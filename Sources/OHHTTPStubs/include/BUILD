_PUBLIC_HEADERS = [
    "Compatibility.h",
    "JSON/OHHTTPStubsResponse+JSON.h",
    "NSURLSession/NSURLRequest+HTTPBodyTesting.h",
    "OHHTTPStubs.h",
    "OHHTTPStubsResponse.h",
    "OHPathHelpers/OHPathHelpers.h",
]

objc_library(
    name = "OHHTTPStubs",
    srcs = glob(
        [
            "**/*.h",
            "**/*.m",
        ],
        exclude = _PUBLIC_HEADERS,
    ),
    hdrs = _PUBLIC_HEADERS,
    includes = [
        ".",
        "HTTPMessage",
        "JSON",
        "NSURLSession",
        "OHPathHelpers",
    ],
)
