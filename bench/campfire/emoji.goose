namespace campfire;
import std;

// Emoji_Presentation, Extended_Pictographic, and variation selector 16.
fn emoji_codepoint(c: u32) -> bool {
    let starts = [169,174,8252,8265,8482,8505,8596,8617,8986,9000,9096,9167,9193,9208,9410,9642,9654,9664,9723,9728,9735,9748,9872,9992,10004,10006,10013,10017,10024,10035,10052,10055,10060,10062,10067,10071,10083,10133,10145,10160,10175,10548,11013,11035,11088,11093,12336,12349,12951,12953,65039,126976,127245,127279,127340,127358,127374,127377,127405,127489,127514,127535,127538,127548,127561,128326,128640,128884,128981,129036,129096,129114,129160,129198,129292,129340,129351,130048];
    let ends = [169,174,8252,8265,8482,8505,8601,8618,8987,9000,9096,9167,9203,9210,9410,9643,9654,9664,9726,9733,9746,9861,9989,10002,10004,10006,10013,10017,10024,10036,10052,10055,10060,10062,10069,10071,10087,10135,10145,10160,10175,10549,11015,11036,11088,11093,12336,12349,12951,12953,65039,127231,127247,127279,127345,127359,127374,127386,127487,127503,127514,127535,127546,127551,128317,128591,128767,128895,129023,129039,129103,129119,129167,129279,129338,129349,129791,131069];
    var low: i64=0; var high=starts.len;
    while low<high { let middle=(low+high)/2; if c<starts[middle] { high=middle; } else if c>ends[middle] { low=middle+1; } else { return true; } }
    return false;
}

fn all_emoji(text: const u8[:]) -> bool {
    if text.len==0 { return false; }
    var i: i64=0;
    while i<text.len {
        let first=text[i]; i+=1;
        var c: u32=first; var extra: i64=0;
        if first>=240 { c=first & 7; extra=3; } else if first>=224 { c=first & 15; extra=2; } else if first>=192 { c=first & 31; extra=1; }
        if i+extra>text.len { return false; }
        for j in extra { if text[i] & 192 != 128 { return false; } c=(c << 6) | (text[i] & 63); i+=1; }
        if !emoji_codepoint(c) { return false; }
    }
    return true;
}
