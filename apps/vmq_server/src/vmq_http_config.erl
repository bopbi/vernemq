%% Copyright 2018 Erlio GmbH Basel Switzerland (http://erl.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(vmq_http_config).
-export([config/1]).

-callback routes() -> [{string(), atom(), any()}].
config(Opts) ->
    HttpLocal = element(2, lists:keyfind(http_modules, 1, Opts)),
    HttpLocalList = [
        list_to_atom(string:strip(Token))
     || Token <- string:tokens(string:trim(HttpLocal, both, "[]"), ",")
    ],

    HttpModules =
        case {HttpLocalList, vmq_config:get_env(http_modules)} of
            {[], _} -> vmq_config:get_env(http_modules);
            {LocalModules, _} -> LocalModules
        end,
    config(HttpModules, []).

config([HttpModule | Rest], Routes) when is_atom(HttpModule) ->
    try
        ModRoutes = apply(HttpModule, routes, []),
        config(Rest, Routes ++ ModRoutes)
    catch
        E:R ->
            lager:error("can't call ~p:routes() due to ~p ~p", [HttpModule, E, R]),
            config(Rest, Routes)
    end;
config([], Routes) ->
    Routes.
