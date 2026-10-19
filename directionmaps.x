
%hook VKMapModel

- (int)tileStyleForMapLayer:(unsigned int)layer {
    int s = %orig;
    if (s == 18) return 20; // style 18 is no longer available. this is for the road name balloons. style 20 works fine for this.
    return s;
}

- (void)configureTileSources { // disabling the realistic tiles, so it just displays the regular tiles. this just stops it from transitioning to the dead tiles. couldn't get this one fixed with a rewrite.
    Ivar iv = class_getInstanceVariable(object_getClass(self), "_activeMapLayers");
    if (iv) {
        char *layers = (char *)(__bridge void *)self + ivar_getOffset(iv);
        for (int row = 0; row < 3; row++) {
            char *r = layers + row * 26;
            if (r[10]) {
                r[2] = 1;
                r[6] = 1;
                r[8] = 1;
                r[9] = 1;
            }
        }
    }
    %orig;
}

%end