classdef Log < handle
    properties (Constant)
        instance = util.Log()
        Symbols = [[".","~","#","#","#","#"]; [" ","-","=","#","#","#"]; [" ",":","-","#","#","#"]];
    end
    properties
        level util.LogLevel = util.LogLevel.Trace
        subLevel double = util.LogSubLevel.Low
    end
    methods(Static)
        function [val,subVal] = getLevel()
            val = util.Log.instance.level;
            subVal = util.Log.instance.subLevel;
        end
        function setLevel(level,subLevel)
            arguments
                level (1,1) util.LogLevel
                subLevel (1,1) util.LogSubLevel = util.LogSubLevel.Low
            end
            obj = util.Log.instance;
            obj.level = level;
            obj.subLevel = subLevel;
        end
        function message(level,message,subLevel,Symbol)
            arguments
                level util.LogLevel
                message string
                subLevel util.LogSubLevel = util.LogSubLevel.Mid
                Symbol string = string.empty
            end
            obj = util.Log.instance;
            if isempty(Symbol)
                Symbol = util.Log.Symbols(3-double(subLevel), double(level)/10 + 1);
            end
            if obj.level + obj.subLevel <= level + subLevel
                util.printing.title(message,Symbol=Symbol);
            end
        end
        function trace(message,subLevel,symbol)
            arguments
                message
                subLevel = util.LogSubLevel.Mid
                symbol = string.empty
            end
            util.Log.message(util.LogLevel.Trace,message,subLevel,symbol);
        end
        function debug(message,subLevel,symbol)
            arguments
                message
                subLevel = util.LogSubLevel.Mid
                symbol = string.empty
            end
            util.Log.message(util.LogLevel.Debug,message,subLevel,symbol);
        end
        function info(message,subLevel,symbol)
            arguments
                message
                subLevel = util.LogSubLevel.Mid
                symbol = string.empty
            end
            util.Log.message(util.LogLevel.Info,message,subLevel,symbol);
        end
        function warn(message,subLevel,symbol)
            arguments
                message
                subLevel = util.LogSubLevel.Mid
                symbol = string.empty
            end
            util.Log.message(util.LogLevel.Warn,message,subLevel,symbol);
        end
        function error(message,subLevel,symbol)
            arguments
                message
                subLevel = util.LogSubLevel.Mid
                symbol = string.empty
            end
            util.Log.message(util.LogLevel.Error,message,subLevel,symbol);
        end
        function fatal(message,subLevel,symbol)
            arguments
                message
                subLevel = util.LogSubLevel.Mid
                symbol = string.empty
            end
            util.Log.message(util.LogLevel.Fatal,message,subLevel,symbol);
        end
    end
end