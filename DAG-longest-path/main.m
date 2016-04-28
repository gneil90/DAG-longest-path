//
//  main.m
//  DAG-longest-path
//
//  Created by Neil Galiaskarov on 4/28/16.
//  Copyright © 2016 neilg. All rights reserved.
//

#import <Foundation/Foundation.h>

#warning define your own path to the map.text 

#define DAG_MAP_PATH @"/Users/aidapedersen/Documents/Apps/DAG-longest-path/DAG-longest-path/map.txt"

typedef enum {
  DAGCardinalDirectionWest,
  DAGCardinalDirectionEast,
  DAGCardinalDirectionNorth,
  DAGCardinalDirectionSouth
} DAGCardinalDirection;

@class DAGRoute;
@interface DAGMap : NSObject

@property (copy, nonatomic) NSArray * topology;
@property (copy, nonatomic) NSDictionary * orientations;
@property (strong, nonatomic) DAGRoute * longestRoute;

/*!
 *@abstract init method
 *@param path absolute path of .txt map
 *@param error indicates the error during the reading file
 */
- (instancetype)initWithPath:(NSString *)path error:(NSError **)error;
- (void)findLongestPath;

@end

int main(int argc, const char * argv[]) {
  @autoreleasepool {
      // insert code here...
    NSError * err = nil;
    DAGMap * map = [[DAGMap alloc] initWithPath:DAG_MAP_PATH error:&err];
    if (err) {
      NSLog(@"error during .txt initialization: %@", err);
      return 0;
    }
    [map findLongestPath];
    NSLog(@"%@", map.longestRoute);

  }
    return 0;
}


@interface DAGMap()

@property (assign, nonatomic) NSInteger rowNumber;
@property (assign, nonatomic) NSInteger columnNumber;

@property (strong, nonatomic) NSArray * lines;

/*!
 *@abstract parses input text file map
 */

- (void)parseTextFileAtPath:(NSString *)path error:(NSError **)error;

@end

@interface DAGVertex : NSObject

@property (assign, nonatomic) NSInteger row;
@property (assign, nonatomic) NSInteger column;

@property (assign, nonatomic) NSInteger elevation;

@property (copy, nonatomic) NSArray * allowedVertices;

- (instancetype)initWithElevation:(NSInteger)elevation
                              row:(NSInteger)row
                           column:(NSInteger)column;

/*!
 *@abstract checks if can go to the vertex
 */
- (BOOL)isAvailableOrientation:(DAGVertex *)vertex;

/*!
 *@abstract ["%@ %@", column row];
 */
- (NSString *)uniqueIdentifier;

@end

@interface DAGRoute : NSObject
- (instancetype)initWithVertices:(NSArray *)vertices;
- (instancetype)initWithVertex:(DAGVertex *)vertex;

@property (assign, nonatomic, getter=getRouteLength) NSInteger routeLength;
@property (assign, nonatomic, getter=getDeltaElevation) NSInteger deltaElevation;

@property (strong, nonatomic) NSMutableArray * vertices;

- (void)addVertex:(DAGVertex *)vertex;

@end

@implementation DAGMap

- (instancetype)initWithPath:(NSString *)path error:(NSError **)error {
  self = [super init];
  if (self) {
    [self parseTextFileAtPath:path error:error];
    self.longestRoute = [[DAGRoute alloc] init];
  }
  return self;
}

- (void)parseTextFileAtPath:(NSString *)path error:(NSError **)error {
  @autoreleasepool {
    NSString * map = [[NSString alloc] initWithContentsOfFile:path
                                                     encoding:NSUTF8StringEncoding error:error];
    if (error) {
    }
    
    NSArray* lines = [map componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableArray * topology = [NSMutableArray array];
    
    for (NSInteger row = 0; row < lines.count; row++) {
      NSString * line = lines[row];
      if (row == 0) {
        NSArray * rowAndColumn = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        self.rowNumber = [[rowAndColumn firstObject] integerValue];
        self.columnNumber = [[rowAndColumn lastObject] integerValue];
        continue;
      }
      
      NSArray * elevations = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      NSMutableArray * lineVertices = [NSMutableArray array];
      
      if (elevations.count != self.columnNumber) {
        //go to the next line
        continue;
      }
      
      for (NSInteger column = 0; column < elevations.count; column++) {
        NSInteger elevation = [elevations[column] integerValue];
        DAGVertex * vertex = [[DAGVertex alloc] initWithElevation:elevation row:row-1 column:column];
        [lineVertices addObject:vertex];
      }
      [topology addObject:lineVertices];
    }
    self.topology = topology;
  }
}

/*!
 *@abstract Constructs NSDictionary which holds array with available vertices for each element with format  ["{row column} : [Vertex1,...,VertexN]"]
 */

- (void)setupVerticesOrientations {
  NSMutableDictionary * orientations = [NSMutableDictionary dictionary];
  for (NSInteger row = 0; row < self.topology.count; row++) {
    NSArray * line = self.topology[row];
    for (NSInteger column = 0; column < line.count; column++) {
      @autoreleasepool {
        DAGVertex * currentVertex = self.topology[row][column];
        NSArray * availableVertexOrientations = [self getAvailableOrintationsForVertex:currentVertex];
        orientations[[currentVertex uniqueIdentifier]] = availableVertexOrientations;
      }
    }
  }
  self.orientations = orientations;
}

/*!
 *@abstract Checks the available orientation for particular vertex
 */
- (NSArray *)getAvailableOrintationsForVertex:(DAGVertex *)vertex {
  NSMutableArray * vertices = [NSMutableArray array];
  
  for (DAGCardinalDirection direction = DAGCardinalDirectionWest; direction <= DAGCardinalDirectionSouth; direction++) {
    DAGVertex * directionVertex = [self getVertexForDirection:direction originVertex:vertex];
    if ([vertex isAvailableOrientation:directionVertex]) {
      [vertices addObject:directionVertex];
    }
  }
  return [NSArray arrayWithArray:vertices];
}

/*!
 *@abstract Obtain the east,west,south,north vertex
 */

- (DAGVertex *)getVertexForDirection:(DAGCardinalDirection)direction originVertex:(DAGVertex *)vertex {
  NSArray * line = self.topology[vertex.row];

  NSInteger row, column = 0;
  switch (direction) {
    case DAGCardinalDirectionSouth:
      row = vertex.row - 1;
      column = vertex.column;
      break;
      
    case DAGCardinalDirectionNorth:
      row = vertex.row + 1;
      column = vertex.column;
      break;
      
    case DAGCardinalDirectionEast:
      row = vertex.row;
      column = vertex.column + 1;
      break;
      
    default:
      row = vertex.row;
      column = vertex.column - 1;
      break;
  }
  
  //bounds check
  if (row >= 0 && column >=0 && row < self.topology.count && column < line.count) {
    DAGVertex * vertex = self.topology[row][column];
    return vertex;
  } else {
    return nil;
  }
}

/*!
 *@abstract finds longest path with largest drop
 */

- (void)findLongestPath {
  [self setupVerticesOrientations];
  
  DAGRoute * maxRoute = [[DAGRoute alloc] init];

  for (NSInteger row = 0; row < self.topology.count; row++) {
    NSArray * line = self.topology[row];
    for (NSInteger column = 0; column < line.count; column++) {
      DAGVertex * vertex = self.topology[row][column];
      NSArray * routes = [self findRoutesFrom:vertex];
      
      for (DAGRoute * route in routes) {
        if (route.routeLength > maxRoute.routeLength) {
          maxRoute = route;
        } else if (route.routeLength == maxRoute.routeLength) {
          if (route.deltaElevation > maxRoute.deltaElevation) {
            maxRoute = route;
          }
        }
      }
    }
  }
  
  self.longestRoute = maxRoute;
}

/*!
 *@abstract Constructs all available routes for the DAGRoute with root node (first object in vertices is root)
 */

- (NSArray *)finalizeRoute:(DAGRoute *)oldRoute {
  NSMutableArray * newRoutes = [NSMutableArray array];
  NSArray * availableVertices = self.orientations[[oldRoute.vertices.lastObject uniqueIdentifier]];
  
  if (availableVertices.count == 0) {
    return @[oldRoute];
  }
  
  for (DAGVertex * vertex in availableVertices) {
    DAGRoute * route = [oldRoute copy];
    [route addVertex:vertex];
    
    [newRoutes addObjectsFromArray:[self finalizeRoute:route]];
  }
  
  return newRoutes;
}

/*!
 *@abstract Constructs all available routes for the vertex with root node (first object in vertices is root)
 */

- (NSArray *)findRoutesFrom:(DAGVertex *)vertex {
  DAGRoute * route = [[DAGRoute alloc] initWithVertex:vertex];
  NSArray * sequences = [self finalizeRoute:route];
  return sequences;
}

@end

@implementation DAGVertex

- (instancetype)initWithElevation:(NSInteger)elevation
                              row:(NSInteger)row
                           column:(NSInteger)column {
  self = [super init];
  if (self) {
    self.row = row;
    self.column = column;
    self.elevation = elevation;
  }
  return self;
}

- (BOOL)isAvailableOrientation:(DAGVertex *)vertex {
  if ([vertex isKindOfClass:[DAGVertex class]]) {
    return self.elevation > vertex.elevation;
  } else {
    return NO;
  }
}

- (NSString *)uniqueIdentifier {
  NSString * key = [NSString stringWithFormat:@"%@ %@", [@(self.row) stringValue], [@(self.column) stringValue]];
  return key;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Elevation:%ld Row: %ld, Column: %ld", (long)self.elevation, (long)self.row, (long)self.column];
}
@end

@implementation DAGRoute

- (instancetype)initWithVertices:(NSArray *)vertices {
  self = [self init];
  if (self) {
    [self.vertices addObjectsFromArray:vertices];
  }
  
  return self;
}

- (instancetype)initWithVertex:(DAGVertex *)vertex
{
  self = [self init];
  if (self) {
    [self addVertex:vertex];
  }
  return self;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.vertices = [NSMutableArray array];
  }
  return self;
}

- (NSInteger)getRouteLength {
  return self.vertices.count;
}

- (NSInteger)getDeltaElevation {
  if (self.vertices.count < 2) {
    return 0;
  }
  
  DAGVertex * firstVertex = [self.vertices firstObject];
  DAGVertex * lastVertex = [self.vertices lastObject];
  
  return firstVertex.elevation - lastVertex.elevation;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"delta:%ld, vertice length: %ld, first vertex:%@, last vertex:%@", self.deltaElevation, self.routeLength, self.vertices.firstObject, self.vertices.lastObject];
}

- (void)addVertex:(DAGVertex *)vertex {
  [self.vertices addObject:vertex];
}

- (id)copy {
  DAGRoute * route = [[DAGRoute alloc] init];
  route.vertices = [self.vertices mutableCopy];
  return route;
}


@end
