using eBooks.Models.Responses;

namespace eBooks.Interfaces
{
    public interface IRecommenderService
    {
        Task TrainModel(int maxIterations = 200, int approximationRank = 150, float alpha = 0.02f, float lambda = 0.04f, int batchIterations = 10, int patience = 3);
        Task LoadModel();
        Task<List<BooksRes>> GetRecommendedBooks(int bookId, int numberOfRecommendations = 5);
    }
}
