#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An indication of a placemark’s precision.
 
 A placemark’s `MBPlacemarkScope` indicates a feature’s size or importance,
 whereas its precision indicates how far the reported location may be from the
 actual real-world location.
 */
typedef NSString *MBPlacemarkPrecision NS_TYPED_EXTENSIBLE_ENUM;

/**
 The placemark represents a specific building with a location on the
 building’s rooftop or at one of its entrances.
 */
extern MBPlacemarkPrecision const MBPlacemarkPrecisionBuilding;

/**
 The placemark represents a tract or parcel of land with a location at the
 centroid.
 */
extern MBPlacemarkPrecision const MBPlacemarkPrecisionParcel;

/**
 The placemark represents an address that has been interpolated from an address
 range. The actual location is generally somewhere along the same block of the
 same street as the placemark’s location.
 */
extern MBPlacemarkPrecision const MBPlacemarkPrecisionInterpolated;

/**
 The placemark represents a block along a street or an intersection between two
 or more streets.
 */
extern MBPlacemarkPrecision const MBPlacemarkPrecisionIntersection;

/*
 The placemark represents an entire street with a location at its midpoint.
 */
extern MBPlacemarkPrecision const MBPlacemarkPrecisionStreet;

NS_ASSUME_NONNULL_END
