-module(certifi_tests).

-include_lib("eunit/include/eunit.hrl").

-ifdef('OTP_20_AND_ABOVE').
reproducible_module_test() ->
    %% When compiled with +deterministic, only version is left out.
    ?assertMatch([{version,[_|_]}], certifi:module_info(compile)).
-endif.

cacerts_test_() ->
    Certs = [Cert1, Cert2, Cert3 | _] = certifi:cacerts(),
    [?_assertEqual(138, length(Certs))
    ,?_assertMatch(<<48,130,2,157,48,130,2,36,160,3,2,1,2,2,12,8,189,133,151,108,_/binary>>, Cert1)
    ,?_assertMatch(<<48,130,2,96,48,130,2,7,160,3,2,1,2,2,12,13,106,95,8,63,40,_/binary>>, Cert2)
    ,?_assertMatch(<<48,130,5,218,48,130,3,194,160,3,2,1,2,2,12,5,247,14,134,218, _/binary>>, Cert3)
    ,?_assertMatch(<<48,130,3,117,48,130,2,93,160,3,2,1,2,2,11,4,0,0,0,0,1,21,75,90,195,148,48,13,6,_/binary>>, lists:last(Certs))
    ].
