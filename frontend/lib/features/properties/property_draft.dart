import 'package:image_picker/image_picker.dart';

class PropertyDraft {
  PropertyDraft({
    this.propertyType,
    this.intention,
    this.cityId,
    this.cityName,
    this.districtId,
    this.districtName,
    this.neighborhoodId,
    this.neighborhoodName,
    this.price,
    this.area,
    this.stratum = 1,
    this.address = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.parkingSpots = 0,
    this.description = '',
    List<XFile>? photos,
  }) : photos = photos ?? <XFile>[];

  String? propertyType;
  String? intention;
  int? cityId;
  String? cityName;
  int? districtId;
  String? districtName;
  int? neighborhoodId;
  String? neighborhoodName;
  num? price;
  num? area;
  int stratum;
  String address;
  int bedrooms;
  int bathrooms;
  int parkingSpots;
  String description;
  final List<XFile> photos;

  bool get hasStep1Completed =>
      propertyType != null &&
      propertyType!.isNotEmpty &&
      intention != null &&
      intention!.isNotEmpty;

  bool get hasStep2Completed {
    return cityId != null &&
        districtId != null &&
        neighborhoodId != null &&
        (price ?? 0) > 0 &&
        (area ?? 0) > 0 &&
        stratum > 0 &&
        address.trim().isNotEmpty &&
        bedrooms > 0 &&
        bathrooms > 0 &&
        description.trim().isNotEmpty;
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'type': propertyType,
      'description': description.trim(),
      'intention': intention,
      'stratum': stratum,
      'neighborhood_id': neighborhoodId,
      'address': address.trim(),
      'rooms': bedrooms,
      'bathrooms': bathrooms,
      'parking_spots': parkingSpots,
      'price': (price ?? 0).toDouble(),
      'area': (area ?? 0).toDouble(),
    };
  }
}
