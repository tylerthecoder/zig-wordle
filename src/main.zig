const std = @import("std");
const wordfile = "./words.txt";

const Guess = struct {
    word: [5]u8,
    marks: [5]u8,
};

fn print_guess(stdout: anytype, guess: Guess) !void {
    const black_text = "\x1b[30m";
    const green_bg = "\x1b[42m";
    const yellow_bg = "\x1b[43m";
    const reset = "\x1b[0m";

    for (0..5) |i| {
        const word_char = guess.word[i];
        const mark = guess.marks[i];
        if (mark == 2) {
            try stdout.print("{s}{s}{u}{s}", .{ black_text, green_bg, word_char, reset });
        } else if (mark == 1) {
            try stdout.print("{s}{s}{u}{s}", .{ black_text, yellow_bg, word_char, reset });
        } else {
            try stdout.print("{u}", .{word_char});
        }
    }
    try stdout.print("\n", .{});
}

fn print_board(board: std.ArrayList(Guess)) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    std.debug.print("Printing", .{});
    // Clear the entire screen
    try stdout.writeAll("\x1b[2J");

    // Move the cursor to the top-left corner (home position)
    try stdout.writeAll("\x1b[H");

    for (board.items) |guess| {
        try print_guess(stdout, guess);
    }
    try bw.flush(); // don't forget to flush!
}

fn make_guess(guess_word: [5]u8, target_word: [5]u8) Guess {
    var new_marks = [5]u8{ 0, 0, 0, 0, 0 };
    for (0..5) |j| {
        const guess_letter = guess_word[j];
        var right_letter = false;
        var right_place = false;
        for (0..5) |k| {
            const target_letter = target_word[k];
            if (target_letter == guess_letter) {
                right_letter = true;
                if (j == k) {
                    right_place = true;
                }
            }
        }

        if (right_place) {
            new_marks[j] = 2;
        } else if (right_letter) {
            new_marks[j] = 1;
        }
    }

    return Guess{
        .word = guess_word,
        .marks = new_marks,
    };
}

pub fn get_input(board: std.ArrayList(Guess)) ![5]u8 {
    while (true) {
        var input: [5]u8 = undefined;
        const stdin = std.io.getStdIn().reader();
        const bytes_read = try stdin.read(&input);
        const stdout_file = std.io.getStdOut().writer();
        if (bytes_read != 5 or input[4] == '\n') {
            try stdout_file.writeAll("Too few characters");
            try stdin.skipUntilDelimiterOrEof('\n');
            try print_board(board);
        } else {
            try stdin.skipUntilDelimiterOrEof('\n');
            return input;
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = std.ArrayList(Guess).init(allocator);
    defer board.deinit();

    const file = try std.fs.cwd().openFile(wordfile, .{});
    defer file.close();

    const file_size = try file.getEndPos();

    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    _ = try file.readAll(buffer);

    // pick a random element from the buffer.
    var prng = std.rand.DefaultPrng.init(4173998);
    const rng = prng.random();

    var word_count: u32 = 0;
    for (buffer) |char| {
        if (char == '\n') {
            word_count += 1;
        }
    }

    const random_index = rng.intRangeAtMost(u32, 0, word_count - 1);
    const word_loc = random_index * 6;
    const word = buffer[word_loc .. word_loc + 5];
    const word_copied: [5]u8 = word[0..5].*;

    while (true) {
        const input = try get_input(board);
        const guess = make_guess(input, word_copied);
        try board.append(guess);
        try print_board(board);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
