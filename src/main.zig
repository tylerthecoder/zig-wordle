const std = @import("std");

const words = @embedFile("./words.txt");

const black_text = "\x1b[30m";
const green_bg = "\x1b[42m";
const yellow_bg = "\x1b[43m";
const reset = "\x1b[0m";

const Guess = struct {
    word: [5]u8,
    marks: [5]u8,
};

fn print_guess(stdout: anytype, guess: Guess) !void {
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

    try stdout.writeAll("Lets get ziggy, enter a 5 letter word:\n");

    for (board.items) |guess| {
        try print_guess(stdout, guess);
    }
    try bw.flush(); // don't forget to flush!
}

fn make_guess(guess_word: [5]u8, target_word: [5]u8) Guess {
    var marks = [5]u8{ 0, 0, 0, 0, 0 };

    var letters_used = [5]u8{ 0, 0, 0, 0, 0 };

    for (0..5) |i| {
        const guess_letter = guess_word[i];
        for (0..5) |j| {
            const target_letter = target_word[j];
            if (target_letter == guess_letter) {
                if (i == j) {
                    marks[i] = 2;
                    letters_used[j] = 1;
                }
            }
        }
    }

    for (0..5) |i| {
        const guess_letter = guess_word[i];
        var right_letter = false;
        for (0..5) |j| {
            const target_letter = target_word[j];
            if (target_letter == guess_letter and letters_used[j] == 0) {
                right_letter = true;
                marks[i] = 1;
                letters_used[j] = 1;
                break;
            }
        }
    }

    return Guess{
        .word = guess_word,
        .marks = marks,
    };
}

fn run_test(target_word: [5]u8, guess_word: [5]u8, expected_marks: [5]u8) !void {
    const guess = make_guess(guess_word, target_word);
    try std.testing.expectEqual(expected_marks, guess.marks);
}

test "Test judging same words" {
    try run_test("tyler".*, "tyler".*, [5]u8{ 2, 2, 2, 2, 2 });
    try run_test("tyler".*, "lllll".*, [5]u8{ 0, 0, 2, 0, 0 });
    try run_test("tyler".*, "lltll".*, [5]u8{ 1, 0, 1, 0, 0 });
}

test "Judging differnt words" {}

pub fn get_input(board: std.ArrayList(Guess)) ![5]u8 {
    while (true) {
        var input: [5]u8 = undefined;
        const stdin = std.io.getStdIn().reader();
        _ = try stdin.read(&input);
        const stdout_file = std.io.getStdOut().writer();

        var parsed_input: [5]u8 = undefined;
        var is_valid = true;
        var index: u8 = 0;
        for (input) |byte| {
            if (!std.ascii.isAlphabetic(byte)) {
                is_valid = false;
                break;
            }
            parsed_input[index] = std.ascii.toLower(byte);
            index += 1;
        }

        if (!is_valid) {
            try stdout_file.writeAll("Invalid Input. Please enter 5 letters");
            try stdin.skipUntilDelimiterOrEof('\n');
            try print_board(board);
        } else {
            try stdin.skipUntilDelimiterOrEof('\n');
            return parsed_input;
        }
    }
}

fn get_did_win(board: std.ArrayList(Guess)) bool {
    const last = board.getLast();

    for (last.marks) |mark| {
        if (mark != 2) {
            return false;
        }
    }

    return true;
}

fn print_end(board: std.ArrayList(Guess)) !void {
    try print_board(board);

    const score = board.items.len;
    const stdout_file = std.io.getStdOut().writer();
    try stdout_file.print("Your score was: {X}\n", .{score});
}

fn get_random_word() ![5]u8 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    // var prng = std.rand.DefaultPrng.init(124738927498);
    const rng = prng.random();

    var word_count: u32 = 0;
    for (words) |char| {
        if (char == '\n') {
            word_count += 1;
        }
    }

    const random_index = rng.intRangeAtMost(u32, 0, word_count - 1);
    const word_loc = random_index * 6;
    const word = words[word_loc .. word_loc + 5];
    const word_copied: [5]u8 = word[0..5].*;

    std.debug.print("The word: {s}", .{word_copied});
    return word_copied;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var board = std.ArrayList(Guess).init(allocator);
    defer board.deinit();

    const random_word = try get_random_word();

    try print_board(board);

    while (true) {
        const input = try get_input(board);
        const guess = make_guess(input, random_word);
        try board.append(guess);
        try print_board(board);
        const did_win = get_did_win(board);
        if (did_win) {
            try print_end(board);
            break;
        }
    }
}
