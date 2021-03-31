mimerl
=====

library to handle mimetypes

Present a way to parse IANA mediatype as defined here:
http://www.iana.org/assignments/media-types/media-types.xhtml


Build
-----

    $ make

Example of usage:
-----------------

    1> mimerl:extension(<<"c">>).
    <<"text/x-c">>
    2> mimerl:filename(<<"test.cpp">>).
    <<"text/x-c">>
    3> mimerl:mime_to_exts(<<"text/plain">>).
    [<<"txt">>,<<"text">>,<<"conf">>,<<"def">>,<<"list">>,
     <<"log">>,<<"in">>]
