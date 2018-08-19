import {LoggerFactoryOptions, LFService, LogGroupRule, LogLevel} from 'typescript-logging';
 
const options = new LoggerFactoryOptions()
    .addLogGroupRule(new LogGroupRule(new RegExp('.+'), LogLevel.Debug));

export const factory = LFService.createNamedLoggerFactory('LoggerFactory', options);
