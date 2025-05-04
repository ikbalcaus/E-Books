﻿using System;
using System.Collections.Generic;

namespace eBooks.Database.Models;

public partial class AccessRight
{
    public int AccessRightId { get; set; }

    public int UserId { get; set; }

    public int BookId { get; set; }

    public virtual Book Book { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
