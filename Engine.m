//
//  Engine.m
//  RSpace
//
//  Created by Randy Lai on 11/8/13.
//  Copyright (c) 2013 Randy Lai. All rights reserved.
//

#define R_INTERFACE_PTRS 1
#define CSTACK_DEFNS 1
#import "Engine.h"
#include <Rembedded.h>
#include <Rinterface.h>
#include "RSpaceWindowController.h"

static Engine* R = nil;

char* commandBuffer=0;

int R_ReadConsole(const char *prompt, unsigned char *buf, int len, int addtohistory){
    NSLog(@"Start readconsole");
    char *c;
    int skipPC=0;
    
    [R waitToRead];
    
    [[R console] performSelectorOnMainThread:@selector(writeText:)
                                           withObject:[NSString stringWithUTF8String: prompt]
                                        waitUntilDone:YES];

    if (!commandBuffer){
        NSString* str = [[[Engine R] console] readText];
        commandBuffer = (char*)[str UTF8String];
    }

   // get a compelete line
    c = commandBuffer;
    while (*c && *c!='\n' && *c!='\r') c++;
    if (*c=='\r') {
        *c='\n';
        if (c[1]=='\n') skipPC=1;
    }
    if (*c) c++;

    if (c-commandBuffer>=len) c=commandBuffer+(len-1);
    memcpy(buf, commandBuffer, c-commandBuffer);
    buf[c-commandBuffer] = 0;
    if (skipPC) c++;
    if (*c)
        commandBuffer=c;
    else
        commandBuffer=0;

    [[R console] performSelectorOnMainThread:@selector(writeInput:)
                                           withObject:[NSString stringWithUTF8String: (char*) buf]
                                        waitUntilDone:YES];

    return 1;
}


void R_WriteConsoleEx(const char *buf, int len, int oType){
	NSString *s = nil;
   // NSLog(@"R output is %s", buf);
	s = [[NSString alloc] initWithUTF8String:buf];
    if (!s) s = [[NSString alloc] initWithCString:buf encoding:NSASCIIStringEncoding];
    if (s) {
        [R writePipe: s];
	}
}

@implementation Engine{
    NSPipe* pipeHandle;
    NSFileHandle* pipeReadHandle;
    NSFileHandle* pipeWriteHandle;
    NSCondition* condition;
    unsigned long buflen;
}

@synthesize console;
         
- (id) init{
    self = [super init];

    pipeHandle = [[NSPipe pipe] init];
    pipeReadHandle = [pipeHandle fileHandleForReading] ;
    pipeWriteHandle = [pipeHandle fileHandleForWriting] ;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handlePipe:) name: NSFileHandleReadCompletionNotification object: pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify] ;

    condition = [[NSCondition alloc] init];
    
    buflen = 0;
    
    return self;
}

- (void) writePipe: (NSString*) str{
    // for gaining speed, use buffer to write text
    [pipeWriteHandle writeData: [str dataUsingEncoding:NSUTF8StringEncoding]];
    // for synchronization
    buflen += [str length];
}

- (void) handlePipe: notification{

    
    [pipeReadHandle readInBackgroundAndNotify] ;
    
    NSData* d = [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem];
    NSString* str = [[NSString alloc] initWithData:d  encoding: NSUTF8StringEncoding] ;

    // perform on mainthread for thread safty
    [[[Engine R] console] performSelectorOnMainThread:@selector(writeInput:)
                                           withObject:str waitUntilDone:YES];

    buflen -= [str length];
    NSLog(@"buflen = %lu", buflen);
    if (buflen==0){
        [condition lock];
        [condition signal];
        [condition unlock];
    }
}

- (void) waitToRead{
    if (buflen >0){
        [condition lock];
        [condition wait];
        [condition unlock];
    }
}

+ (Engine*) R
{
    if (R==nil)
        R=[[Engine alloc] init];
    return R;
}

- (void) activate
{
    char *args[4]={ "R", "--no-save", 0 };

	int argc=0;
	while (args[argc]) argc++;

    if (!getenv("R_HOME")) {
        NSLog(@"R_HOME is not set.");
        return;
    }

    NSLog(@"initializing R");


    Rf_initEmbeddedR(argc, args);


    R_Outputfile = NULL;
    R_Consolefile = NULL;
    R_Interactive = 1;
    ptr_R_ReadConsole =  R_ReadConsole;
    ptr_R_WriteConsole = NULL;
    ptr_R_WriteConsoleEx = R_WriteConsoleEx;

    // disable stack limit checking
    R_CStackLimit = -1;

   // do all NSEvents before running repl
    [self doEvents];
}


- (void) run_repl
{

    NSLog(@"run repl");
    R_ReplDLLinit();

    while (R_ReplDLLdo1() > 0) {
    }

    NSLog(@"Finished");
}


- (void) doEvents{
    NSEvent *event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
    [NSApp sendEvent: event];
}

@end
