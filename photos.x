
%hook GEOVoltaireSearchProvider

-(void)requesterDidFinish:(id)result {
    NSLog(@"[MapsX] result class -> %@", NSStringFromClass([result class]));
    
    NSLog(@"[MapsX] search request -> %@", [result responseForRequest:[[GEORequester requests] objectAtIndex:0]]);
    return %orig;
}

%end