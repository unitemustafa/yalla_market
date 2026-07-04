const regionRequiredMessage =
    'Select a market browsing region before loading market content.';

bool isRegionRequiredPayload(Object? data) {
  if (data is! Map<String, dynamic>) return false;
  return data['requires_region_selection'] == true;
}
