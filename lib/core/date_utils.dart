/// Půlnoc daného dne (místní čas).
DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Půlnoc následujícího dne. Počítá s kalendářními dny, ne s 24 h,
/// aby fungovala i při přechodu na letní/zimní čas.
DateTime endOfDayExclusive(DateTime d) => DateTime(d.year, d.month, d.day + 1);
