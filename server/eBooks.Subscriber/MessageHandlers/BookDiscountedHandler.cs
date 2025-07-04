﻿using eBooks.Models.Messages;
using eBooks.Database;
using Microsoft.EntityFrameworkCore;
using eBooks.Database.Models;
using eBooks.Subscriber.Services;
using eBooks.Subscriber.Interfaces;
using eBooks.Subscriber.MessageHandlers;
using eBooks.Services;

namespace eBooks.MessageHandlers
{
    public class BookDiscountedHandler : BaseMessageHandler<BookDiscounted>, IMessageHandler<BookDiscounted>
    {
        public BookDiscountedHandler(EBooksContext db, EmailService emailService)
            : base(db, emailService)
        {
        }

        public async Task SendEmail(BookDiscounted message)
        {
            var emails = await _db.Set<Wishlist>().Where(x => x.BookId == message.Book.BookId).Include(x => x.User).Select(x => x.User.Email).ToListAsync();
            foreach (var email in emails)
            {
                Console.WriteLine($"Sending email to: {email}");
                string subject = $"Book \"{message.Book.Title}\" is on discount";
                string body = $"Book \"{message.Book.Title}\" is on discount, new price is {Helpers.CalculateDiscountedPrice(message.Book.Price, message.Book.DiscountPercentage, message.Book.DiscountStart, message.Book.DiscountEnd)}";
                await _emailService.SendEmailAsync(email, subject, body);
            }
        }

        public async Task NotifyUser(BookDiscounted message)
        {
            var userIds = await _db.Set<Wishlist>().Where(x => x.BookId == message.Book.BookId).Select(x => x.UserId).ToListAsync();
            Console.WriteLine($"Sending notification to users: {string.Join(", ", userIds)}");
            var notifications = userIds.Select(userId => new Notification
            {
                UserId = userId,
                BookId = message.Book.BookId,
                Message = $"Book \"{message.Book.Title}\" is on discount, new price is {Helpers.CalculateDiscountedPrice(message.Book.Price, message.Book.DiscountPercentage, message.Book.DiscountStart, message.Book.DiscountEnd)}"
            }).ToList();
            _db.Set<Notification>().AddRange(notifications);
            await _db.SaveChangesAsync();
        }
    }
}
