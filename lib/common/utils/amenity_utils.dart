import 'package:flutter/material.dart';

IconData getAmenityIcon(String amenity) {
  switch (amenity) {
    case 'WiFi':
    case 'Wifi':
      return Icons.wifi;
    case 'AC':
      return Icons.ac_unit;
    case 'Parking':
    case 'Bike Parking':
      return Icons.local_parking;
    case 'Gym':
      return Icons.fitness_center;
    case 'Pool':
      return Icons.pool;
    case 'Tiled Floor':
      return Icons.grid_on;
    case 'Attached Bath':
    case 'Shared Washroom':
      return Icons.bathtub_outlined;
    case 'Balcony':
      return Icons.balcony;
    case 'Shared Kitchen':
    case 'Kitchen':
      return Icons.kitchen;
    case 'Generator':
      return Icons.power;
    case 'Security':
      return Icons.security;
    case 'Furnished':
      return Icons.chair;
    case 'Lift':
      return Icons.elevator;
    case 'Water Filter':
      return Icons.water_drop;
    case 'Meal System':
      return Icons.restaurant;
    case 'Line Gas':
      return Icons.local_fire_department;
    case 'Rooftop':
      return Icons.roofing;
    case 'Open View':
      return Icons.landscape;
    case 'Drawing Room':
    case 'Dining Space':
      return Icons.living;
    case '24/7 Water':
      return Icons.water;
    default:
      return Icons.check_circle_outline;
  }
}
