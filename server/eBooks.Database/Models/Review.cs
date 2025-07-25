﻿using System;
using System.Collections.Generic;

namespace eBooks.Database.Models;

public partial class Review
{
    public int UserId { get; set; }

    public int BookId { get; set; }

    public DateTime ModifiedAt { get; set; }

    public int Rating { get; set; }

    public string? Comment { get; set; }

    public int? ReportedById { get; set; }

    public string? ReportReason { get; set; }

    public virtual Book Book { get; set; } = null!;

    public virtual User? ReportedBy { get; set; }

    public virtual User User { get; set; } = null!;
}
