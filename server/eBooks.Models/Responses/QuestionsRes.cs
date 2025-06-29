﻿namespace eBooks.Models.Responses
{
    public class QuestionsRes
    {
        public int QuestionId { get; set; }
        public UsersRes User { get; set; }
        public string Question1 { get; set; }
        public string? Answer { get; set; }
        public UsersRes? AnsweredBy { get; set; }
    }
}
