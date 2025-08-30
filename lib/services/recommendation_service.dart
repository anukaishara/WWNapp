// // ðŸ”§ Updated recommendation_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

// class RecommendationService {
//   static Future<void> updateUserRecommendations(String userEmail) async {
//     final firestore = FirebaseFirestore.instance;
//     String firestoreDocId = userEmail.replaceAll('.', ',');

//     print('ðŸ“¥ Reading user document for $firestoreDocId...');

//     final userDoc = await firestore.collection('userdata').doc(firestoreDocId).get();
//     if (!userDoc.exists) {
//       print('âŒ User document not found for $firestoreDocId.');
//       return;
//     }

//     Map<String, int> categoryCount = {};
//     int totalCount = 0;

//     // ðŸ“Œ Handle preferences (weight = 2)
//     List<String> preferences = [];
//     try {
//       preferences = List<String>.from(userDoc.get('preferences') ?? []);
//     } catch (e) {
//       print('âš ï¸ No preferences found or error reading preferences: $e');
//     }
//     for (var pref in preferences) {
//       categoryCount[pref] = (categoryCount[pref] ?? 0) + 2;
//       totalCount += 2;
//     }

//     // ðŸ“Œ Handle bookmarks (weight = 1)
//     try {
//       final bookmarks = await firestore
//           .collection('userdata')
//           .doc(firestoreDocId)
//           .collection('bookmarks')
//           .get();

//       for (var doc in bookmarks.docs) {
//         String? mainCat = doc.data()['mainCategory'];
//         String? subCat = doc.data()['subCategory'];
//         if (mainCat != null && subCat != null) {
//           String category = "$mainCat-$subCat";
//           categoryCount[category] = (categoryCount[category] ?? 0) + 1;
//           totalCount++;
//         }
//       }
//     } catch (e) {
//       print('âš ï¸ Error reading bookmarks: $e');
//     }

//     // ðŸ“Œ Handle watched (weight = 1)
//     try {
//       final watched = await firestore
//           .collection('userdata')
//           .doc(firestoreDocId)
//           .collection('watched')
//           .get();

//       for (var doc in watched.docs) {
//         String? mainCat = doc.data()['mainCategory'];
//         String? subCat = doc.data()['subCategory'];
//         if (mainCat != null && subCat != null) {
//           String category = "$mainCat-$subCat";
//           categoryCount[category] = (categoryCount[category] ?? 0) + 1;
//           totalCount++;
//         }
//       }
//     } catch (e) {
//       print('âš ï¸ Error reading watched: $e');
//     }

//     if (totalCount == 0) {
//       print('âš ï¸ No data found to calculate recommendations.');
//       return;
//     }

//     // ðŸ§  Calculate final data
//     Map<String, Map<String, dynamic>> recommendationData = {};
//     categoryCount.forEach((category, count) {
//       double percentage = double.parse(((count / totalCount) * 100).toStringAsFixed(2));
//       recommendationData[category] = {
//         'count': count,
//         'percentage': percentage,
//       };
//     });

//    print('Final Recommendation data for $firestoreDocId:');
// recommendationData.forEach((category, data) {
//   print('  $category: count=${data['count']}, percentage=${data['percentage']}%');
// });

//     // â˜ï¸ Store in Firestore
//     try {
//       await firestore
//           .collection('userdata')
//           .doc(firestoreDocId)
//           .set({'recommendations': recommendationData}, SetOptions(merge: true));
//       print('ðŸ“¤ Successfully stored recommendations in Firestore.');
//     } catch (e) {
//       print('âŒ Failed to store recommendation data: $e');
//     }
//   }
// }




// import 'package:cloud_firestore/cloud_firestore.dart';

// class RecommendationService {
//   static Future<void> updateUserRecommendations(String userEmail) async {
//     final firestore = FirebaseFirestore.instance;
//     String firestoreDocId = userEmail.replaceAll('.', ',');

//     print('🔥 Reading user document for $firestoreDocId...');

//     final userDoc = await firestore.collection('userdata').doc(firestoreDocId).get();
//     if (!userDoc.exists) {
//       print('❌ User document not found for $firestoreDocId.');
//       return;
//     }

//     Map<String, int> categoryCount = {};
//     int totalCount = 0;

//     // 📌 Handle preferences (weight = 2)
//     List<String> preferences = [];
//     try {
//       preferences = List<String>.from(userDoc.get('preferences') ?? []);
//     } catch (e) {
//       print('⚠️ No preferences found or error reading preferences: $e');
//     }
//     for (var pref in preferences) {
//       categoryCount[pref] = (categoryCount[pref] ?? 0) + 2;
//       totalCount += 2;
//     }

//     // 📌 Handle bookmarks (weight = 1)
//     try {
//       final bookmarkCounts = Map<String, dynamic>.from(userDoc.get('bookmarkSubCategoryCounts') ?? {});
//       bookmarkCounts.forEach((mainCat, subMap) {
//         if (subMap is Map<String, dynamic>) {
//           subMap.forEach((subCat, count) {
//             if (count is int) {
//               String category = "$mainCat-$subCat";
//               categoryCount[category] = (categoryCount[category] ?? 0) + count;
//               totalCount += count;
//             }
//           });
//         }
//       });
//     } catch (e) {
//       print('⚠️ Error reading bookmark counts: $e');
//     }

//     // 📌 Handle watched/history (weight = 1)
//     try {
//       final historyCounts = Map<String, dynamic>.from(userDoc.get('historySubCategoryCounts') ?? {});
//       historyCounts.forEach((mainCat, subMap) {
//         if (subMap is Map<String, dynamic>) {
//           subMap.forEach((subCat, count) {
//             if (count is int) {
//               String category = "$mainCat-$subCat";
//               categoryCount[category] = (categoryCount[category] ?? 0) + count;
//               totalCount += count;
//             }
//           });
//         }
//       });
//     } catch (e) {
//       print('⚠️ Error reading history counts: $e');
//     }

//     if (totalCount == 0) {
//       print('⚠️ No data found to calculate recommendations.');
//       return;
//     }

//     // 🧠 Calculate final data
//     Map<String, Map<String, dynamic>> recommendationData = {};
//     categoryCount.forEach((category, count) {
//       double percentage = double.parse(((count / totalCount) * 100).toStringAsFixed(2));
//       recommendationData[category] = {
//         'count': count,
//         'percentage': percentage,
//       };
//     });

//     print('Final Recommendation data for $firestoreDocId:');
//     recommendationData.forEach((category, data) {
//       print('  $category: count=${data['count']}, percentage=${data['percentage']}%');
//     });

//     // 💾 Store in Firestore
//     try {
//       await firestore
//           .collection('userdata')
//           .doc(firestoreDocId)
//           .set({'recommendations': recommendationData}, SetOptions(merge: true));
//       print('✅ Successfully stored recommendations in Firestore.');
//     } catch (e) {
//       print('❌ Failed to store recommendation data: $e');
//     }
//   }
// }



// import 'package:cloud_firestore/cloud_firestore.dart';

// class RecommendationService {
//   static Future<void> updateUserRecommendations(String userEmail) async {
//     final firestore = FirebaseFirestore.instance;
//     String firestoreDocId = userEmail.replaceAll('.', ',');

//     print(' Reading user document for $firestoreDocId...');

//     final userDoc = await firestore.collection('userdata').doc(firestoreDocId).get();
//     if (!userDoc.exists) {
//       print(' User document not found for $firestoreDocId.');
//       return;
//     }

//     Map<String, int> categoryCount = {};
//     int totalCount = 0;

//     //  Preferences (weight = 2)
//     List<String> preferences = [];
//     try {
//       preferences = List<String>.from(userDoc.get('preferences') ?? []);
//     } catch (e) {
//       print(' No preferences found or error reading preferences: $e');
//     }
//     for (var pref in preferences) {
//       categoryCount[pref] = (categoryCount[pref] ?? 0) + 2;
//       totalCount += 2;
//     }

//     //  Bookmarks (weight = 1)
//     try {
//       final bookmarkCounts = Map<String, dynamic>.from(userDoc.get('bookmarkSubCategoryCounts') ?? {});
//       bookmarkCounts.forEach((mainCat, subMap) {
//         if (subMap is Map<String, dynamic>) {
//           subMap.forEach((subCat, count) {
//             if (count is int && count > 0) {
//               String category = "$mainCat-$subCat";
//               categoryCount[category] = (categoryCount[category] ?? 0) + count;
//               totalCount += count;
//             }
//           });
//         }
//       });
//     } catch (e) {
//       print(' Error reading bookmark counts: $e');
//     }

//     //  History (weight = 1)
//     try {
//       final historyCounts = Map<String, dynamic>.from(userDoc.get('historySubCategoryCounts') ?? {});
//       historyCounts.forEach((mainCat, subMap) {
//         if (subMap is Map<String, dynamic>) {
//           subMap.forEach((subCat, count) {
//             if (count is int && count > 0) {
//               String category = "$mainCat-$subCat";
//               categoryCount[category] = (categoryCount[category] ?? 0) + count;
//               totalCount += count;
//             }
//           });
//         }
//       });
//     } catch (e) {
//       print(' Error reading history counts: $e');
//     }

//     if (totalCount == 0) {
//       print(' No data found to calculate recommendations.');
//       return;
//     }

//     //  Calculate percentages and normalize total to 100%
//     Map<String, Map<String, dynamic>> recommendationData = {};
//     double currentSum = 0;
//     List<String> categories = categoryCount.keys.toList();
//     String lastCategory = categories.last;

//     for (var category in categories) {
//       int count = categoryCount[category]!;
//       double perc = double.parse(((count / totalCount) * 100).toStringAsFixed(2));
//       recommendationData[category] = {
//         'count': count,
//         'percentage': perc,
//       };
//       currentSum += perc;
//     }

//     // // Adjust last category to ensure sum = 100%
//     // recommendationData[lastCategory]!['percentage'] += (100 - currentSum);

//     // Adjust last category to ensure sum = 100% and keep 2 decimals ****
//     recommendationData[lastCategory]!['percentage'] = double.parse(
//     (recommendationData[lastCategory]!['percentage'] + (100 - currentSum)).toStringAsFixed(2)
//     );


//     print('Final Recommendation data for $firestoreDocId:');
//     recommendationData.forEach((category, data) {
//       print('  $category: count=${data['count']}, percentage=${data['percentage']}%');
//     });

//     //  Store in Firestore (overwrite only recommendations section)
//     try {
//       await firestore
//           .collection('userdata')
//           .doc(firestoreDocId)
//           .set({'recommendations': recommendationData}, SetOptions(merge: true));
//       print(' Successfully stored recommendations in Firestore.');
//     } catch (e) {
//       print(' Failed to store recommendation data: $e');
//     }
//   }
// }



import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationService {
  static Future<void> updateUserRecommendations(String userEmail) async {
    final firestore = FirebaseFirestore.instance;
    String firestoreDocId = userEmail.replaceAll('.', ',');


    final userDoc = await firestore.collection('userdata').doc(firestoreDocId).get();
    if (!userDoc.exists) {

      return;
    }

    Map<String, int> categoryCount = {};
    int totalCount = 0;

    // 🔹 Preferences (weight = 2)
    List<String> preferences = [];
    try {
      preferences = List<String>.from(userDoc.get('preferences') ?? []);
    } catch (e) {

    }
    for (var pref in preferences) {
      categoryCount[pref] = (categoryCount[pref] ?? 0) + 2;
      totalCount += 2;
    }

    // 🔹 Bookmarks (weight = 1)
    try {
      final bookmarkCounts = Map<String, dynamic>.from(userDoc.get('bookmarkSubCategoryCounts') ?? {});
      bookmarkCounts.forEach((mainCat, subMap) {
        if (subMap is Map<String, dynamic>) {
          subMap.forEach((subCat, count) {
            if (count is int && count > 0) {
              String category = "$mainCat-$subCat";
              categoryCount[category] = (categoryCount[category] ?? 0) + count;
              totalCount += count;
            }
          });
        }
      });
    } catch (e) {
    }

    // 🔹 History (weight = 1)
    try {
      final historyCounts = Map<String, dynamic>.from(userDoc.get('historySubCategoryCounts') ?? {});
      historyCounts.forEach((mainCat, subMap) {
        if (subMap is Map<String, dynamic>) {
          subMap.forEach((subCat, count) {
            if (count is int && count > 0) {
              String category = "$mainCat-$subCat";
              categoryCount[category] = (categoryCount[category] ?? 0) + count;
              totalCount += count;
            }
          });
        }
      });
    } catch (e) {
    }

    if (totalCount == 0) {
      return;
    }

    // 🔹 Calculate percentages and normalize to 100%
    Map<String, Map<String, dynamic>> recommendationData = {};
    double currentSum = 0;
    List<String> categories = categoryCount.keys.toList();
    String lastCategory = categories.last;

    for (var category in categories) {
      int count = categoryCount[category]!;
      double perc = double.parse(((count / totalCount) * 100).toStringAsFixed(2));
      recommendationData[category] = {
        'count': count,
        'percentage': perc,
      };
      currentSum += perc;
    }

    // Adjust last category to ensure total = 100%
    recommendationData[lastCategory]!['percentage'] = double.parse(
      (recommendationData[lastCategory]!['percentage'] + (100 - currentSum)).toStringAsFixed(2),
    );


    recommendationData.forEach((category, data) {

    });

    // 🔥 Overwrite recommendations section ONLY (delete then set)
    try {
      await firestore.collection('userdata').doc(firestoreDocId).update({
        'recommendations': FieldValue.delete(),
      });

      await firestore.collection('userdata').doc(firestoreDocId).update({
        'recommendations': recommendationData,
      });


    } catch (e) {
    }
  }
}
