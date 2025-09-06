using eBooks.Database;
using eBooks.Models.Responses;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using Microsoft.ML.Data;
using eBooks.Interfaces;
using eBooks.Database.Models;
using MapsterMapper;
using Microsoft.Extensions.Logging;

namespace eBooks.Services
{
    public class RecommenderService : IRecommenderService
    {
        protected EBooksContext _db;
        protected IMapper _mapper;
        protected SemaphoreSlim _lock = new(1, 1);
        protected MLContext _mlContext = null!;
        protected ITransformer _model = null!;
        protected string ModelFilePath = Path.Combine(AppContext.BaseDirectory, "ml-model.zip");
        protected ILogger<RecommenderService> _logger;

        public RecommenderService(EBooksContext db, IMapper mapper, ILogger<RecommenderService> logger)
        {
            _db = db;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task TrainModel(int maxIterations = 200, int approximationRank = 150, float alpha = 0.02f, float lambda = 0.04f, int batchIterations = 10, int patience = 3)
        {
            _logger.LogInformation("Training started...");
            await _lock.WaitAsync();
            try
            {
                _mlContext ??= new MLContext();
                var interactions = await _db.AccessRights.Where(x => !x.IsHidden).ToListAsync();
                if (interactions.Count == 0)
                    return;
                var trainingData = interactions.Select(x => new UserBookInteraction
                {
                    UserId = (uint)x.UserId,
                    BookId = (uint)x.BookId,
                    Label = 1f
                });
                var data = _mlContext.Data.LoadFromEnumerable(trainingData);
                var split = _mlContext.Data.TrainTestSplit(data, testFraction: 0.2, seed: 123);
                ITransformer? bestModel = null;
                double bestRmse = double.MaxValue;
                int noImprovement = 0;
                for (int totalIters = batchIterations; totalIters <= maxIterations; totalIters += batchIterations)
                {
                    var options = new Microsoft.ML.Trainers.MatrixFactorizationTrainer.Options
                    {
                        MatrixColumnIndexColumnName = nameof(UserBookInteraction.UserId),
                        MatrixRowIndexColumnName = nameof(UserBookInteraction.BookId),
                        LabelColumnName = nameof(UserBookInteraction.Label),
                        LossFunction = Microsoft.ML.Trainers.MatrixFactorizationTrainer.LossFunctionType.SquareLossOneClass,
                        Alpha = alpha,
                        Lambda = lambda,
                        NumberOfIterations = totalIters,
                        ApproximationRank = approximationRank
                    };
                    var est = _mlContext.Recommendation().Trainers.MatrixFactorization(options);
                    var model = est.Fit(split.TrainSet);
                    var predictions = model.Transform(split.TestSet);
                    var metrics = _mlContext.Regression.Evaluate(predictions);
                    if (metrics.RootMeanSquaredError + 1e-6 < bestRmse)
                    {
                        bestRmse = metrics.RootMeanSquaredError;
                        bestModel = model;
                        noImprovement = 0;
                    }
                    else
                    {
                        noImprovement++;
                        if (noImprovement >= patience)
                            break;
                    }
                }
                if (bestModel != null)
                {
                    _model = bestModel;
                    var modelPath = Path.Combine(AppContext.BaseDirectory, ModelFilePath);
                    await using var fs = new FileStream(modelPath, FileMode.Create, FileAccess.Write, FileShare.Read, 4096, useAsync: true);
                    await Task.Run(() => _mlContext.Model.Save(_model, split.TrainSet.Schema, fs));
                }
            }
            finally
            {
                _lock.Release();
                _logger.LogInformation("Training finished...");
            }
        }

        public async Task LoadModel()
        {
            await _lock.WaitAsync();
            try
            {
                if (_mlContext == null)
                    _mlContext = new MLContext();
                var modelPath = Path.Combine(AppContext.BaseDirectory, ModelFilePath);
                if (File.Exists(modelPath))
                {
                    await using var stream = new FileStream(modelPath, FileMode.Open, FileAccess.Read, FileShare.Read, bufferSize: 4096, useAsync: true);
                    _model = _mlContext.Model.Load(stream, out _);
                }
            }
            finally
            {
                _lock.Release();
            }
        }

        public async Task<List<BooksRes>> GetRecommendedBooks(int bookId, int numberOfRecommendations = 5)
        {
            if (_model == null)
                await LoadModel();
            var userIds = await _db.AccessRights.Where(x => x.BookId == bookId && !x.IsHidden).Select(x => x.UserId).Distinct().ToListAsync();
            if (!userIds.Any())
                return new List<BooksRes>();
            var allBooks = await _db.Set<Book>().Where(x => x.StateMachine == "approve" && x.BookId != bookId).ToListAsync();
            var predictionEngine = _mlContext.Model.CreatePredictionEngine<UserBookInteraction, BookPrediction>(_model);
            var scoredBooks = new List<(Book book, float score)>();
            foreach (var book in allBooks)
            {
                float totalScore = 0;
                foreach (var userId in userIds)
                {
                    var prediction = predictionEngine.Predict(new UserBookInteraction
                    {
                        UserId = (uint)userId,
                        BookId = (uint)book.BookId
                    });
                    totalScore += prediction.Score;
                }
                float avgScore = totalScore / userIds.Count;
                scoredBooks.Add((book, avgScore));
            }
            var topBooks = scoredBooks.OrderByDescending(x => x.score).Take(numberOfRecommendations).Select(x => x.book).ToList();
            return _mapper.Map<List<BooksRes>>(topBooks);
        }

        public class UserBookInteraction
        {
            [KeyType(count: 10000)]
            public uint UserId { get; set; }

            [KeyType(count: 10000)]
            public uint BookId { get; set; }

            public float Label { get; set; }
        }

        public class BookPrediction
        {
            public float Score { get; set; }
        }
    }
}
