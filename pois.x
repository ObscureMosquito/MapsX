%hook VKIconAtlas
    
-(void)getIconForName:(NSString*)icon style:(void*)style asynchronous:(BOOL)async handler:(id)handler {
    NSLog(@"[MapsX] icon -> %@", icon);
    if ([icon isEqualToString:@"POI-Pizza"]) {
        return %orig(@"POI-Restaurant", style, async, handler);
    } else if ([icon isEqualToString:@"POI-ChineseFood-default"]) {
        return %orig(@"POI-Restaurant", style, async, handler);
    }
    return %orig;
}

%end