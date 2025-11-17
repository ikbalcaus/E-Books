-- dotnet ef dbcontext scaffold "Name=Database" Microsoft.EntityFrameworkCore.SqlServer --output-dir Models --context-dir . --force --project eBooks.Database/eBooks.Database.csproj --startup-project eBooks.API/eBooks.API.csproj

CREATE DATABASE eBooks;
GO

USE eBooks;
GO

CREATE TABLE Roles (
    RoleId INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(100) NOT NULL
);

CREATE TABLE Users (
    UserId INT PRIMARY KEY IDENTITY,
    UserName NVARCHAR(100) UNIQUE NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    PasswordSalt NVARCHAR(255) NOT NULL,
    FilePath NVARCHAR(255) NOT NULL,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsEmailVerified BIT NOT NULL DEFAULT 0,
    VerificationToken NVARCHAR(100),
    TokenExpiry DATETIME,
    DeletionReason NVARCHAR(255),
    StripeAccountId NVARCHAR(100),
    RoleId INT NOT NULL,
    PublisherVerifiedById INT,
    FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
    FOREIGN KEY (PublisherVerifiedById) REFERENCES Users(UserId)
);

CREATE TABLE Authors (
    AuthorId INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedById INT,
    FOREIGN KEY (ModifiedById) REFERENCES Users(UserId)
);

CREATE TABLE Genres (
    GenreId INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedById INT,
    FOREIGN KEY (ModifiedById) REFERENCES Users(UserId)
);

CREATE TABLE Languages (
    LanguageId INT PRIMARY KEY IDENTITY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedById INT,
    FOREIGN KEY (ModifiedById) REFERENCES Users(UserId)
);

CREATE TABLE Books (
    BookId INT PRIMARY KEY IDENTITY,
    Title NVARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX),
    FilePath NVARCHAR(100) NOT NULL,
    Price DECIMAL(10,2),
    NumberOfPages INT,
    NumberOfViews INT NOT NULL DEFAULT 0,
    LanguageId INT,
    PublisherId INT NOT NULL,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    StateMachine NVARCHAR(50) NOT NULL DEFAULT 'draft',
    ReviewedById INT,
    DiscountPercentage INT,
    DiscountStart DATETIME,
    DiscountEnd DATETIME,
    RejectionReason NVARCHAR(255),
    DeletionReason NVARCHAR(255),
    FOREIGN KEY (LanguageId) REFERENCES Languages(LanguageId),
    FOREIGN KEY (PublisherId) REFERENCES Users(UserId),
    FOREIGN KEY (ReviewedById) REFERENCES Users(UserId)
);

CREATE TABLE BookGenres (
    BookId INT,
    GenreId INT,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BookId, GenreId),
    FOREIGN KEY (BookId) REFERENCES Books(BookId),
    FOREIGN KEY (GenreId) REFERENCES Genres(GenreId)
);

CREATE TABLE BookAuthors (
    BookId INT,
    AuthorId INT,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (BookId, AuthorId),
    FOREIGN KEY (BookId) REFERENCES Books(BookId),
    FOREIGN KEY (AuthorId) REFERENCES Authors(AuthorId)
);

CREATE TABLE Wishlists (
    UserId INT,
    BookId INT,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (UserId, BookId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (BookId) REFERENCES Books(BookId)
);

CREATE TABLE AccessRights (
    UserId INT NOT NULL,
    BookId INT NOT NULL,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsFavorite BIT NOT NULL DEFAULT 0,
    IsHidden BIT NOT NULL DEFAULT 0,
    LastReadPage INT NOT NULL DEFAULT 0,
    PRIMARY KEY (UserId, BookId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (BookId) REFERENCES Books(BookId),
);

CREATE TABLE ReadingProgresses (
    UserId INT,
    BookId INT,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    LastReadPage INT,
    PRIMARY KEY (UserId, BookId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (BookId) REFERENCES Books(BookId)
);

CREATE TABLE Reviews (
    UserId INT,
    BookId INT,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    Rating INT NOT NULL,
    Comment NVARCHAR(MAX),
    ReportedById INT,
    ReportReason NVARCHAR(MAX),
    PRIMARY KEY (UserId, BookId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (BookId) REFERENCES Books(BookId),
    FOREIGN KEY (ReportedById) REFERENCES Users(UserId)
);

CREATE TABLE Reports (
    UserId INT NOT NULL,
    BookId INT NOT NULL,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    Reason NVARCHAR(MAX),
    PRIMARY KEY (UserId, BookId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (BookId) REFERENCES Books(BookId),
);

CREATE TABLE Purchases
(
    PurchaseId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    PublisherId INT NOT NULL,
    BookId INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
    TotalPrice DECIMAL(18,2) NOT NULL,
    PaymentStatus NVARCHAR(50) NOT NULL,
    PaymentMethod NVARCHAR(50) NOT NULL,
    TransactionId NVARCHAR(255) NOT NULL,
    FailureMessage NVARCHAR(255),
    FailureCode NVARCHAR(50),
    FailureReason NVARCHAR(255),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (PublisherId) REFERENCES Users(UserId),
    FOREIGN KEY (BookId) REFERENCES Books(BookId)
);

CREATE TABLE PublisherFollows (
    UserId INT,
    PublisherId INT,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (UserId, PublisherId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (PublisherId) REFERENCES Users(UserId)
);

CREATE TABLE Notifications (
    NotificationId INT PRIMARY KEY IDENTITY,
    BookId INT,
    PublisherId INT,
    UserId INT NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IsRead BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (BookId) REFERENCES Books(BookId),
    FOREIGN KEY (PublisherId) REFERENCES Users(UserId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE TABLE Questions (
    QuestionId INT PRIMARY KEY IDENTITY,
    UserId INT NOT NULL,
    Question NVARCHAR(MAX) NOT NULL,
    Answer NVARCHAR(MAX),
    AnsweredById INT,
    ModifiedAt DATETIME NOT NULL DEFAULT GETDATE(),
    AnsweredAt DATETIME,
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (AnsweredById) REFERENCES Users(UserId)
);
