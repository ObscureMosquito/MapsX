#import <Foundation/Foundation.h>
#import <math.h>
#import <substrate.h>
#import <objc/runtime.h>

typedef struct PointsStruct {
	unsigned x;
	unsigned y;
} PointsStruct;

@interface VKTriangulator : NSObject {
@public
	void* _opaque_triangulator;
	unsigned long _segments_capacity;
	void* _opaque_segments;
	unsigned long _mesh_capacity;
	unsigned* _mesh;
	NSMutableData* _scratch;
}
-(id)init;
-(void)dealloc;
-(id)triangulateIndicesForPoints:(PointsStruct*)points pointCount:(int)count ;
-(char)_triangulateIndicesInto:(id)arg1 ;
@end

typedef struct Node {
    unsigned index;
    double x, y;
    struct Node *prev, *next;
    int steiner;
} Node;

typedef struct {
    Node *pool;
    unsigned count, capacity;
    uint16_t *indices;
    unsigned indexCount, indexCapacity;
    int ok;
} Earcut;

static inline int sign(double v) { return (v>0)-(v<0); }

static double area(Node *p, Node *q, Node *r) {
    return (q->y-p->y)*(r->x-q->x)-(q->x-p->x)*(r->y-q->y);
}

static int equals(Node *a, Node *b) {
    return a->x==b->x&&a->y==b->y;
}

static int onSegment(Node *p, Node *q, Node *r) {
    return q->x<=fmax(p->x, r->x)&&q->x>=fmin(p->x, r->x)&&
    q->y<=fmax(p->y, r->y)&&q->y>=fmin(p->y, r->y);
}

static int intersects(Node *a, Node *b, Node *c, Node *d) {
    int o1=sign(area(a, b, c)), o2=sign(area(a, b, d));
    int o3=sign(area(c, d, a)), o4=sign(area(c, d, b));
    if (o1!=o2&&o3!=o4) return 1;
    if (o1==0&&onSegment(a, c, b)) return 1;
    if (o2==0&&onSegment(a, d, b)) return 1;
    if (o3==0&&onSegment(c, a, d)) return 1;
    if (o4==0&&onSegment(c, b, d)) return 1;
    return 0;
}

static int pointInTriangle(double ax, double ay, double bx, double by,
                           double cx, double cy, double px, double py) {
    return (cx-px)*(ay-py)-(ax-px)*(cy-py)>=0&&
    (ax-px)*(by-py)-(bx-px)*(ay-py)>=0&&
    (bx-px)*(cy-py)-(cx-px)*(by-py)>=0;
}

static int locallyInside(Node *a, Node *b) {
    return area(a->prev, a, a->next)<0?
    (area(a, b, a->next)>=0&&area(a, a->prev, b)>=0):
    (area(a, b, a->prev)<0||area(a, a->next, b)<0);
}

static int middleInside(Node *a, Node *b) {
    Node *p=a;
    int inside=0;
    double px=(a->x+b->x)/2.0, py=(a->y+b->y)/2.0;
    do {
        if (((p->y>py)!=(p->next->y>py))&&p->next->y!=p->y&&
            (px<(p->next->x-p->x)*(py-p->y)/(p->next->y-p->y)+p->x))
            inside=!inside;
        p=p->next;
    } while (p!=a);
    return inside;
}

static int intersectsPolygon(Node *a, Node *b) {
    Node *p=a;
    do {
        if (p->index!=a->index&&p->next->index!=a->index&&
            p->index!=b->index&&p->next->index!=b->index&&
            intersects(p, p->next, a, b)) return 1;
        p=p->next;
    } while (p!=a);
    return 0;
}

static int isValidDiagonal(Node *a, Node *b) {
    return a->next->index!=b->index&&a->prev->index!=b->index&&!intersectsPolygon(a, b)&&
    ((locallyInside(a, b)&&locallyInside(b, a)&&middleInside(a, b)&&
      (area(a->prev, a, b->prev)!=0||area(a, b->prev, b)!=0))||
     (equals(a, b)&&area(a->prev, a, a->next)>0&&area(b->prev, b, b->next)>0));
}

static Node *newNode(Earcut *e, unsigned index, double x, double y) {
    if (e->count>=e->capacity) { e->ok=0; return NULL; }
    Node *n=&e->pool[e->count++];
    n->index=index; n->x=x; n->y=y;
    n->prev=NULL; n->next=NULL; n->steiner=0;
    return n;
}

static Node *insertNode(Earcut *e, unsigned index, double x, double y, Node *last) {
    Node *n=newNode(e, index, x, y);
    if (!n) return last;
    if (!last) { n->prev=n; n->next=n; }
    else { n->next=last->next; n->prev=last; last->next->prev=n; last->next=n; }
    return n;
}

static void removeNode(Node *p) {
    p->next->prev=p->prev;
    p->prev->next=p->next;
}

static Node *splitPolygon(Earcut *e, Node *a, Node *b) {
    Node *a2=newNode(e, a->index, a->x, a->y);
    Node *b2=newNode(e, b->index, b->x, b->y);
    if (!a2||!b2) return a;
    Node *an=a->next, *bp=b->prev;
    a->next=b; b->prev=a;
    a2->next=an; an->prev=a2;
    b2->next=a2; a2->prev=b2;
    bp->next=b2; b2->prev=bp;
    return b2;
}

static Node *filterPoints(Node *start, Node *end) {
    if (!start) return end;
    if (!end) end=start;
    Node *p=start;
    int again;
    do {
        again=0;
        if (!p->steiner&&(equals(p, p->next)||area(p->prev, p, p->next)==0)) {
            removeNode(p);
            p=end=p->prev;
            if (p==p->next) break;
            again=1;
        } else p=p->next;
    } while (again||p!=end);
    return end;
}

static int isEar(Node *ear) {
    Node *a=ear->prev, *b=ear, *c=ear->next;
    if (area(a, b, c)>=0) return 0;
    Node *p=ear->next->next;
    while (p!=ear->prev) {
        if (pointInTriangle(a->x, a->y, b->x, b->y, c->x, c->y, p->x, p->y)&&
            area(p->prev, p, p->next)>=0) return 0;
        p=p->next;
    }
    return 1;
}

static void emitTriangle(Earcut *e, unsigned a, unsigned b, unsigned c) {
    if (e->indexCount+3>e->indexCapacity) { e->ok=0; return; }
    e->indices[e->indexCount++]=(uint16_t)a;
    e->indices[e->indexCount++]=(uint16_t)b;
    e->indices[e->indexCount++]=(uint16_t)c;
}

static Node *cureLocalIntersections(Earcut *e, Node *start) {
    Node *p=start;
    do {
        Node *a=p->prev, *b=p->next->next;
        if (!equals(a, b)&&intersects(a, p, p->next, b)&&
            locallyInside(a, b)&&locallyInside(b, a)) {
            emitTriangle(e, a->index, p->index, b->index);
            removeNode(p); removeNode(p->next);
            p=start=b;
        }
        p=p->next;
    } while (p!=start);
    return filterPoints(p, NULL);
}

static void earcutLinked(Earcut *e, Node *ear, int pass);

static void splitEarcut(Earcut *e, Node *start) {
    Node *a=start;
    do {
        Node *b=a->next->next;
        while (b!=a->prev) {
            if (a->index!=b->index&&isValidDiagonal(a, b)) {
                Node *c=splitPolygon(e, a, b);
                if (!e->ok) return;
                a=filterPoints(a, a->next);
                c=filterPoints(c, c->next);
                earcutLinked(e, a, 0);
                earcutLinked(e, c, 0);
                return;
            }
            b=b->next;
        }
        a=a->next;
    } while (a!=start);
}

static void earcutLinked(Earcut *e, Node *ear, int pass) {
    if (!ear||!e->ok) return;
    Node *stop=ear, *prev, *next;
    while (ear->prev!=ear->next) {
        if (!e->ok) return;
        prev=ear->prev; next=ear->next;
        if (isEar(ear)) {
            emitTriangle(e, prev->index, ear->index, next->index);
            removeNode(ear);
            ear=next->next; stop=next->next;
            continue;
        }
        ear=next;
        if (ear==stop) {
            if (!pass) earcutLinked(e, filterPoints(ear, NULL), 1);
            else if (pass==1) { ear=cureLocalIntersections(e, filterPoints(ear, NULL)); earcutLinked(e, ear, 2); }
            else if (pass==2) splitEarcut(e, ear);
            break;
        }
    }
}


@interface VGLVertexArrayObject : NSObject <NSCoding> {
	unsigned _VAO;
	unsigned _VBO;
	unsigned _EBO[2];
	int _stride;
	id _attributes;
    @public
	int _vertexCount;
    @public
	int _indexCount[2];
	int _vertexPrimitiveType[2];
	unsigned _indexBufferMode;
	unsigned _bindedIndexBuffer;
	unsigned _indicesDirty : 1;
	unsigned _verticesDirty : 1;
	unsigned _vertexUsage : 2;
	unsigned _indexUsage : 2;
	unsigned _attributeCount : 8;
}
@end

@interface VKMapModel : NSObject
- (int)tileStyleForMapLayer:(unsigned int)layer;
- (void)configureTileSources;
@end

%group EnablePolygonPatches
%hook VKTriangulator

- (NSMutableData *)triangulateIndicesForPoints:(PointsStruct *)points pointCount:(int)pointCount {
    NSMutableData *result=%orig;
    if (result&&[result length]>0) return result;
    if (pointCount<3||pointCount>65535) return result;
    uint16_t *ring=(uint16_t *)malloc(pointCount*sizeof(uint16_t));
    if (!ring) return result;
    unsigned int n=0;
    for (int i=0; i<pointCount; i++) {
        unsigned int xi=points[i].x, yi=points[i].y;
        if (n>0) {
            uint16_t pv=ring[n-1];
            if (points[pv].x==xi&&points[pv].y==yi) continue;
        }
        ring[n++]=(uint16_t)i;
    }
    if (n>1) {
        uint16_t a=ring[0], b=ring[n-1];
        if (points[a].x==points[b].x&&points[a].y==points[b].y) n--;
    }
    if (n<3) { free(ring); return result; }
    unsigned int total=n;
    double sum=0;
    unsigned int j=n-1;
    for (unsigned int i=0; i<n; i++) {
        double xi=points[ring[i]].x, yi=points[ring[i]].y;
        double xj=points[ring[j]].x, yj=points[ring[j]].y;
        sum+=(xj-xi)*(yi+yj);
        j=i;
    }
    Earcut e;
    e.capacity=total*3+64;
    e.pool=(Node *)malloc(sizeof(Node)*e.capacity);
    e.indexCapacity=(total+8)*3;
    e.indices=(uint16_t *)malloc(sizeof(uint16_t)*e.indexCapacity);
    e.count=0; e.indexCount=0; e.ok=1;
    if (!e.pool||!e.indices) { free(e.pool); free(e.indices); free(ring); return result; }
    Node *last=NULL;
    if (sum>0) {
        for (unsigned int i=0; i<n; i++)
            last=insertNode(&e, ring[i], points[ring[i]].x, points[ring[i]].y, last);
    } else {
        for (int i=(int)n-1; i>=0; i--)
            last=insertNode(&e, ring[i], points[ring[i]].x, points[ring[i]].y, last);
    }
    Node *outer=filterPoints(last, NULL);
    if (e.ok&&outer&&outer->next!=outer->prev)
        earcutLinked(&e, outer, 0);
    NSMutableData *out=nil;
    if (e.ok&&e.indexCount>=3)
        out=[[NSData dataWithBytes:e.indices length:e.indexCount*sizeof(uint16_t)] mutableCopy];
    free(e.pool); free(e.indices); free(ring);
    return out?out:result;
}

%end

%hook VGLVertexArrayObject

- (unsigned short*)reserveIndices:(int)requestedCount {
    unsigned int mode = MSHookIvar<unsigned int>(self, "_indexBufferMode");
    int *indexCounts = MSHookIvar<int[2]>(self, "_indexCount");
    int currentCount = indexCounts[mode];
    const unsigned int MAX_16BIT_INDICES = 0x10000;
    if ((unsigned int)(currentCount + requestedCount) <= MAX_16BIT_INDICES) {
        return %orig;
    } else {
        return NULL;
    }
}

%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber <= 847.27) {
		%init(EnablePolygonPatches);
	}
}