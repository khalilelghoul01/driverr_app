import 'package:drivers_app/models/direction_details_info.dart';
import 'package:flutter/widgets.dart';
import '../models/directions.dart';
import '../models/trip_history_model.dart';


class AppInfo extends ChangeNotifier{
  Directions? userPickupLocation,userDropOffLocation;
  int countTotalTrips = 0;
  List<String> historyTripsKeyList = [];
  List<TripHistoryModel> historyInformationList = [];

  double totalTimeDriven = 0;
  String driverAverageRating = "5";

  TripHistoryModel? lastTripHistoryInformationModel;
  DirectionDetailsInfo? lastTripDirectionDetailsInformation;

  void updatePickupLocationAddress(Directions userPickupAddress){
    userPickupLocation = userPickupAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Directions userDropOffAddress){
    userDropOffLocation = userDropOffAddress;
    notifyListeners();
  }

  // Will be used in later part of the app through provider
  void updateTotalTrips(int totalTripsCount){
    countTotalTrips = totalTripsCount;
    notifyListeners();
  }

  void updateTotalTripsList(List<String> rideRequestKeyList) {
    historyTripsKeyList = rideRequestKeyList;
    notifyListeners();
  }

  void updateriderequeststatus(String riderequeststatus){
    riderequeststatus = riderequeststatus;
    notifyListeners();
  }

  void updateTotalHistoryInformation(TripHistoryModel eachTripHistoryInformation) {
    historyInformationList.add(eachTripHistoryInformation);
    notifyListeners();
  }

  void updateLastHistoryInformation(TripHistoryModel lastTripHistoryInformation,DirectionDetailsInfo lastTripDirectionDetailsInfo){
    lastTripHistoryInformationModel = lastTripHistoryInformation;
    lastTripDirectionDetailsInformation = lastTripDirectionDetailsInfo;

    notifyListeners();
  }

  void updateDriverRating(String driverRating){
    driverAverageRating = driverRating;
    notifyListeners();
  }
  
int tripCount = 0;
  double totalEarnings = 0.0;
  double todayEarnings = 0.0;
  double weekEarnings = 0.0;
  double monthEarnings = 0.0;

  void updateEarnings(Map<String, dynamic> earningsData) {
    tripCount = earningsData['tripCount'] ?? 0;
    totalEarnings = earningsData['totalEarnings'] ?? 0.0;
    todayEarnings = earningsData['todayEarnings'] ?? 0.0;
    weekEarnings = earningsData['weekEarnings'] ?? 0.0;
    monthEarnings = earningsData['monthEarnings'] ?? 0.0;
    notifyListeners();
  }




}