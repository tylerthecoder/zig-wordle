const std = @import("std");
const wordfile = "./words.txt";

fn print_with_marks(stdout: anytype, marks: [5]u8, word: []u8) !void {
    const black_text = "\x1b[30m";
    const green_bg = "\x1b[42m";
    const reset = "\x1b[0m";
    for (0..5) |i| {
        const word_char = word[i];
        const mark = marks[i];
        if (mark == 1) {
            try stdout.print("{s}{s}{u}{s}", .{ black_text, green_bg, word_char, reset });
        } else {
            try stdout.print("{u}", .{word_char});
        }
    }
    try stdout.print("\n", .{});
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile(wordfile, .{});
    defer file.close();

    const file_size = try file.getEndPos();

    // make allocator for the file
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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

    // now I need to display the word to the screen with green and blue characters

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Clear the entire screen
    try stdout.writeAll("\x1b[2J");

    // Move the cursor to the top-left corner (home position)
    try stdout.writeAll("\x1b[H");

    const marks = [5]u8{ 0, 0, 1, 0, 0 };

    try print_with_marks(stdout, marks, word);

    try bw.flush(); // don't forget to flush!

    var input: [6]u8 = undefined;
    const stdin = std.io.getStdIn().reader();

    _ = try stdin.readUntilDelimiter(&input, '\n');

    var new_marks = [5]u8{ 0, 0, 0, 0, 0 };
    for (0..5) |j| {
        const guess_letter = input[j];
        var right_letter = false;
        var right_place = false;
        for (0..5) |k| {
            const target_letter = word[k];
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

    // move up a line
    try stdout.writeAll("\x1b[1A");

    try stdout.writeAll("\r");

    try print_with_marks(stdout, new_marks, &input);

    try bw.flush();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
