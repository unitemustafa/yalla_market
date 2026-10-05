/// Width for compact cards that leave a preview of the next item visible.
double compactHorizontalCardWidth(double availableWidth) =>
    (availableWidth * 0.80).clamp(0.0, 332.0);
