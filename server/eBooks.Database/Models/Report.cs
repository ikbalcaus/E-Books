﻿using System;
using System.Collections.Generic;

namespace eBooks.Database.Models;

public partial class Report
{
    public int UserId { get; set; }

    public int BookId { get; set; }

    public DateTime ModifiedAt { get; set; }

    public string? Reason { get; set; }

    public virtual Book Book { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
