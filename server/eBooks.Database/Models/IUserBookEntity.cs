﻿namespace eBooks.Database.Models
{
    public interface IUserBookEntity
    {
        int UserId { get; set; }
        int BookId { get; set; }
        User User { get; set; }
        Book Book { get; set; }
        DateTime ModifiedAt { get; set; }
    }
}
