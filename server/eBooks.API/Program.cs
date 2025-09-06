using EasyNetQ;
using eBooks.API;
using eBooks.API.Auth;
using eBooks.API.Filters;
using eBooks.Database;
using eBooks.Interfaces;
using eBooks.Services;
using eBooks.Services.BooksStateMachine;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.FileProviders;
using Microsoft.OpenApi.Models;
using Stripe;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddRouting(options => options.LowercaseUrls = true);
builder.Services.AddHttpContextAccessor();
builder.Services.AddControllers(options => options.Filters.Add<ExceptionFilter>());
StripeConfiguration.ApiKey = builder.Configuration["Stripe:SecretKey"];

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("Admin", policy => policy.RequireRole("Admin"));
    options.AddPolicy("Moderator", policy => policy.RequireRole("Admin", "Moderator"));
    options.AddPolicy("User", policy => policy.RequireRole("Admin", "Moderator", "User"));
});

var mapsterConfig = TypeAdapterConfig.GlobalSettings;
mapsterConfig.Default.IgnoreNullValues(true);
builder.Services.AddSingleton(mapsterConfig);
builder.Services.AddScoped<IMapper, Mapper>();
builder.Services.AddDbContext<EBooksContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("Database"),
        sqlOptions => sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery)
    ).ConfigureWarnings(warnings => warnings.Ignore(CoreEventId.RowLimitingOperationWithoutOrderByWarning))
);
builder.Services.AddSingleton<IBus>(_ => RabbitHutch.CreateBus("host=localhost;username=guest;password=guest"));
builder.Services.AddScoped<AccessControlHandler>();
builder.Services.AddScoped<IRecommenderService, RecommenderService>();
builder.Services.AddAuthentication("BasicAuthentication").AddScheme<AuthenticationSchemeOptions, BasicAuthHandler>("BasicAuthentication", null);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddHttpClient();

builder.Services.AddTransient<IAccessRightsService, AccessRightsService>();
builder.Services.AddTransient<IAuthorsService, AuthorsService>();
builder.Services.AddTransient<IBookAuthorsService, BookAuthorsService>();
builder.Services.AddTransient<IBookGenresService, BookGenresService>();
builder.Services.AddTransient<IBooksService, BooksService>();
builder.Services.AddTransient<IGenresService, GenresService>();
builder.Services.AddTransient<ILanguagesService, LanguagesService>();
builder.Services.AddTransient<INotificationsService, NotificationsService>();
builder.Services.AddTransient<IOverviewService, OverviewService>();
builder.Services.AddTransient<IPublisherFollowsService, PublisherFollowsService>();
builder.Services.AddTransient<IPurchasesService, PurchasesService>();
builder.Services.AddTransient<IQuestionsService, QuestionsService>();
builder.Services.AddTransient<IReportsService, ReportsService>();
builder.Services.AddTransient<IReviewsService, ReviewsService>();
builder.Services.AddTransient<IStripeService, StripeService>();
builder.Services.AddTransient<IRolesService, RolesService>();
builder.Services.AddTransient<IUsersService, UsersService>();
builder.Services.AddTransient<IWishlistService, WishlistService>();

builder.Services.AddTransient<BaseBooksState>();
builder.Services.AddTransient<ApproveBooksState>();
builder.Services.AddTransient<HideBooksState>();
builder.Services.AddTransient<AwaitBooksState>();
builder.Services.AddTransient<DraftBooksState>();
builder.Services.AddTransient<RejectBooksState>();

builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("basicAuth", new Microsoft.OpenApi.Models.OpenApiSecurityScheme()
    {
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "basic"
    });
    options.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference{Type = ReferenceType.SecurityScheme, Id = "basicAuth"}
            },
            new string[] {}
        }
    });
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<EBooksContext>();
    var recommenderService = scope.ServiceProvider.GetRequiredService<IRecommenderService>();
    DbSeeder.SeedRoles(context);
    DbSeeder.SeedLanguages(context);
    if (System.IO.File.Exists(Path.Combine(AppContext.BaseDirectory, "ml-model.zip")))
        await recommenderService.LoadModel();
    else
        await recommenderService.TrainModel();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

var imagesPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images");
var summaryPdfPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "pdfs", "summary");
var booksPdfPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "pdfs", "books");
if (!Directory.Exists(imagesPath))
    Directory.CreateDirectory(imagesPath);
if (!Directory.Exists(summaryPdfPath))
    Directory.CreateDirectory(summaryPdfPath);
if (!Directory.Exists(booksPdfPath))
    Directory.CreateDirectory(booksPdfPath);

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images")),
    RequestPath = "/images"
});
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "pdfs", "summary")),
    RequestPath = "/pdfs/summary"
});

app.UseHttpsRedirection();
app.MapControllers();
app.Run();
