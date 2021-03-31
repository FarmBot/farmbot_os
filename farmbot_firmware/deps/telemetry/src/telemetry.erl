%%%-------------------------------------------------------------------
%% @doc `telemetry' allows you to invoke certain functions whenever a
%% particular event is emitted.
%%
%% For more information see the documentation for {@link attach/4}, {@link attach_many/4}
%% and {@link execute/2}.
%% @end
%%%-------------------------------------------------------------------
-module(telemetry).

-export([attach/4,
         attach_many/4,
         detach/1,
         list_handlers/1,
         execute/2,
         execute/3,
         span/3]).

-include("telemetry.hrl").

-type handler_id() :: term().
-type event_name() :: [atom(), ...].
-type event_measurements() :: map().
-type event_metadata() :: map().
-type event_value() :: number().
-type event_prefix() :: [atom()].
-type handler_config() :: term().
-type handler_function() :: fun((event_name(), event_measurements(), event_metadata(), handler_config()) -> any()).
-type span_result() :: term().
-type span_function() :: fun(() -> {span_result(), event_metadata()}).
-type handler() :: #{id := handler_id(),
                     event_name := event_name(),
                     function := handler_function(),
                     config := handler_config()}.

-export_type([handler_id/0,
              event_name/0,
              event_measurements/0,
              event_metadata/0,
              event_value/0,
              event_prefix/0,
              handler_config/0,
              handler_function/0,
              handler/0,
              span_result/0,
              span_function/0]).

%% @doc Attaches the handler to the event.
%%
%% `handler_id' must be unique, if another handler with the same ID already exists the
%% `{error, already_exists}' tuple is returned.
%%
%% See {@link execute/3} to learn how the handlers are invoked.
%%
%% <b>Note:</b> due to how anonymous functions are implemented in the Erlang VM, it is best to use
%% function captures (i.e. `fun mod:fun/4' in Erlang or `&Mod.fun/4' in Elixir) as event handlers
%% to achieve maximum performance. In other words, avoid using literal anonymous functions
%% (`fun(...) -> ... end' or `fn ... -> ... end') or local function captures (`fun handle_event/4'
%% or `&handle_event/4' ) as event handlers.
%%
%% All the handlers are executed by the process dispatching event. If the function fails (raises,
%% exits or throws) then the handler is removed.
%% Note that you should not rely on the order in which handlers are invoked.
-spec attach(HandlerId, EventName, Function, Config) -> ok | {error, already_exists} when
      HandlerId :: handler_id(),
      EventName :: event_name(),
      Function :: handler_function(),
      Config :: handler_config().
attach(HandlerId, EventName, Function, Config) ->
    attach_many(HandlerId, [EventName], Function, Config).

%% @doc Attaches the handler to many events.
%%
%% The handler will be invoked whenever any of the events in the `event_names' list is emitted. Note
%% that failure of the handler on any of these invocations will detach it from all the events in
%% `event_name' (the same applies to manual detaching using {@link detach/1}).
%%
%% <b>Note:</b> due to how anonymous functions are implemented in the Erlang VM, it is best to use
%% function captures (i.e. `fun mod:fun/4' in Erlang or `&Mod.fun/4' in Elixir) as event handlers
%% to achieve maximum performance. In other words, avoid using literal anonymous functions
%% (`fun(...) -> ... end' or `fn ... -> ... end') or local function captures (`fun handle_event/4'
%% or `&handle_event/4' ) as event handlers.
%%
%% All the handlers are executed by the process dispatching event. If the function fails (raises,
%% exits or throws) then the handler is removed.
%% Note that you should not rely on the order in which handlers are invoked.
-spec attach_many(HandlerId, [EventName], Function, Config) -> ok | {error, already_exists} when
      HandlerId :: handler_id(),
      EventName :: event_name(),
      Function :: handler_function(),
      Config :: handler_config().
attach_many(HandlerId, EventNames, Function, Config) when is_function(Function, 4) ->
    assert_event_names(EventNames),
    telemetry_handler_table:insert(HandlerId, EventNames, Function, Config).

%% @doc Removes the existing handler.
%%
%% If the handler with given ID doesn't exist, `{error, not_found}' is returned.
-spec detach(handler_id()) -> ok | {error, not_found}.
detach(HandlerId) ->
    telemetry_handler_table:delete(HandlerId).

%% @doc Emits the event, invoking handlers attached to it.
%%
%% When the event is emitted, the handler function provided to {@link attach/4} is called with four
%% arguments:
%% <ul>
%% <li>the event name</li>
%% <li>the map of measurements</li>
%% <li>the map of event metadata</li>
%% <li>the handler configuration given to {@link attach/4}</li>
%% </ul>
%%
%% <h4>Best practices and conventions:</h4>
%%
%% <p>
%% While you are able to emit messages of any `event_name' structure, it is recommended that you follow the
%% the guidelines laid out in `span/3' if you are capturing start/stop events.
%% </p>
-spec execute(EventName, Measurements, Metadata) -> ok when
      EventName :: event_name(),
      Measurements :: event_measurements() | event_value(),
      Metadata :: event_metadata().
execute(EventName, Value, Metadata) when is_number(Value) ->
    ?LOG_WARNING("Using execute/3 with a single event value is deprecated. "
                 "Use a measurement map instead.", []),
    execute(EventName, #{value => Value}, Metadata);
execute(EventName, Measurements, Metadata) when is_map(Measurements) and is_map(Metadata) ->
    Handlers = telemetry_handler_table:list_for_event(EventName),
    ApplyFun =
        fun(#handler{id=HandlerId,
                     function=HandlerFunction,
                     config=Config}) ->
            try
                HandlerFunction(EventName, Measurements, Metadata, Config)
            catch
                ?WITH_STACKTRACE(Class, Reason, Stacktrace)
                    detach(HandlerId),
                    ?LOG_ERROR("Handler ~p has failed and has been detached. "
                               "Class=~p~nReason=~p~nStacktrace=~p~n",
                               [HandlerId, Class, Reason, Stacktrace])
            end
        end,
    lists:foreach(ApplyFun, Handlers).

%% @doc Emit start, and stop/exception events, invoking the handlers attached to each.
%%
%% When this function is called, 2 events will be emitted via `execute/3'. Those events will be one of the following
%% pairs:
%% <ul>
%% <li>`EventPrefix ++ [start]' and  `EventPrefix ++ [stop]'</li>
%% <li>`EventPrefix ++ [start]' and `EventPrefix ++ [exception]'</li>
%% </ul>
%%
%% However, note that in case the current processes crashes due to an exit signal
%% of another process, then none or only part of those events would be emitted.
%% Below is a breakdown of the measurements and metadata associated with each individual event.
%%
%% For `telemetry' events denoting the <strong>start</strong> of a larger event, the following data is provided:
%% <p>
%% <ul>
%% <li>
%% Event:
%% ```
%% EventPrefix ++ [start]
%% '''
%% </li>
%% <li>
%% Measurements:
%% ```
%% #{
%%   % The current system time in native units from
%%   % calling: erlang:system_time()
%%   system_time => integer()
%% }
%% '''
%% </li>
%% <li>
%% Metadata:
%% ```
%% #{
%%   % User defined metadata
%%   ...
%% }
%% '''
%% </li>
%% </ul>
%% </p>
%%
%% For `telemetry' events denoting the <strong>stop</strong> of a larger event, the following data is provided:
%% <p>
%% <ul>
%% <li>
%% Event:
%% ```
%% EventPrefix ++ [stop]
%% '''
%% </li>
%% <li>
%% Measurements:
%% ```
%% #{
%%   % The current monotonic time minus the start monotonic time in native units
%%   % by calling: erlang:monotonic_time() - start_monotonic_time
%%   duration => integer()
%% }
%% '''
%% </li>
%% <li>
%% Metadata:
%% ```
%% #{
%%   % An optional error field if the stop event is as the result of an error
%%   % but not necessarily an exception. Additional user defined metadata can
%%   % also be added here.
%%   error => term(),
%%   ...
%% }
%% '''
%% </li>
%% </ul>
%% </p>
%%
%% For `telemetry' events denoting an <strong>exception</strong> of a larger event, the following data is provided:
%% <p>
%% <ul>
%% <li>
%% Event:
%% ```
%% EventPrefix ++ [exception]
%% '''
%% </li>
%% <li>
%% Measurements:
%% ```
%% #{
%%   % The current monotonic time minus the start monotonic time in native units
%%   % derived by calling: erlang:monotonic_time() - start_monotonic_time
%%   duration => integer()
%% }
%% '''
%% </li>
%% <li>
%% Metadata:
%% ```
%% #{
%%   kind => throw | error | exit,
%%   reason => term(),
%%   stacktrace => list(),
%%   % User defined metadata from the start event
%%    ...
%% }
%% '''
%% </li>
%% </ul>
%% </p>
-spec span(event_prefix(), event_metadata(), span_function()) -> span_result().
span(EventPrefix, StartMetadata, SpanFunction) ->
    StartTime = erlang:monotonic_time(),
    execute(EventPrefix ++ [start], #{system_time => erlang:system_time()}, StartMetadata),

    try {_, #{}} = SpanFunction() of
      {Result, StopMetadata} ->
          execute(EventPrefix ++ [stop], #{duration => erlang:monotonic_time() - StartTime}, StopMetadata),
          Result
    catch
        ?WITH_STACKTRACE(Class, Reason, Stacktrace)
            execute(
                EventPrefix ++ [exception],
                #{duration => erlang:monotonic_time() - StartTime},
                StartMetadata#{kind => Class, reason => Reason, stacktrace => Stacktrace}
            ),
            erlang:raise(Class, Reason, Stacktrace)
    end.

%% @equiv execute(EventName, Measurements, #{})
-spec execute(EventName, Measurements) -> ok when
      EventName :: event_name(),
      Measurements :: event_measurements() | event_value().
execute(EventName, Measurements) ->
    execute(EventName, Measurements, #{}).

%% @doc Returns all handlers attached to events with given prefix.
%%
%% Handlers attached to many events at once using `attach_many/4' will be listed once for each
%% event they're attached to.
%% Note that you can list all handlers by feeding this function an empty list.
-spec list_handlers(event_prefix()) -> [handler()].
list_handlers(EventPrefix) ->
    assert_event_prefix(EventPrefix),
    [#{id => HandlerId,
       event_name => EventName,
       function => Function,
       config => Config} || #handler{id=HandlerId,
                                     event_name=EventName,
                                     function=Function,
                                     config=Config} <- telemetry_handler_table:list_by_prefix(EventPrefix)].

%%

-spec assert_event_names(term()) -> [ok].
assert_event_names(List) when is_list(List) ->
    [assert_event_name(E) || E <- List];
assert_event_names(Term) ->
    erlang:error(badarg, Term).

-spec assert_event_prefix(term()) -> ok.
assert_event_prefix(List) when is_list(List) ->
    case lists:all(fun erlang:is_atom/1, List) of
        true ->
            ok;
        false ->
            erlang:error(badarg, List)
    end;
assert_event_prefix(List) ->
    erlang:error(badarg, List).

-spec assert_event_name(term()) -> ok.
assert_event_name([_ | _] = List) ->
    case lists:all(fun erlang:is_atom/1, List) of
        true ->
            ok;
        false ->
            erlang:error(badarg, List)
    end;
assert_event_name(Term) ->
    erlang:error(badarg, Term).
