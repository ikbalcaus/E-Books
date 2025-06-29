﻿using eBooks.Database;
using eBooks.Database.Models;
using eBooks.Models.Messages;
using eBooks.Subscriber.Interfaces;
using eBooks.Subscriber.Services;

namespace eBooks.Subscriber.MessageHandlers
{
    public class BookDeactivatedHandler : BaseMessageHandler<BookDeactivated>, IMessageHandler<BookDeactivated>
    {
        public BookDeactivatedHandler(EBooksContext db, EmailService emailService)
            : base(db, emailService)
        {
        }

        public async Task SendEmail(BookDeactivated message)
        {
            var email = message.Book.Publisher.Email;
            string notificationMessage;
            if (message.Book.Publisher.DeletionReason != null)
                notificationMessage = $"Your book is deactivated. Reason: {message.Book.DeletionReason}";
            else
                notificationMessage = "Your book is reactivated";
            Console.WriteLine($"Sending email to: {email}");
            await _emailService.SendEmailAsync(email, "Book update", notificationMessage);
        }

        public async Task NotifyUser(BookDeactivated message)
        {
            string notificationMessage;
            if (message.Book.Publisher.DeletionReason != null)
                notificationMessage = $"Your book is deactivated. Reason: {message.Book.DeletionReason}";
            else
                notificationMessage = "Your book is reactivated";
            var userId = message.Book.Publisher.UserId;
            Console.WriteLine($"Sending notification to user: {userId}");
            var notification = new Notification
            {
                UserId = userId,
                BookId = message.Book.BookId,
                Message = notificationMessage
            };
            _db.Set<Notification>().Add(notification);
            await _db.SaveChangesAsync();
        }
    }
}
