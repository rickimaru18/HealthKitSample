//
//  StepsView.swift
//  HealthKitSample
//
//  Created by Rick Krystianne Lim on 4/7/21.
//

import SwiftUI
import HealthKit

struct StepsView: View {
    var body: some View {
        Button("Read Steps", action: readSteps)
    }
}

private func readSteps() {
    if HKHealthStore.isHealthDataAvailable() {
        print("HKHealthStore available")
        // Add code to use HealthKit here.
        let healthStore = HKHealthStore()
    
        guard let stepCountType = HKObjectType.quantityType(
            forIdentifier: .stepCount
        ) else {
            fatalError("*** Unable to get the step count type ***")
        }
        
        guard let distanceType = HKObjectType.quantityType(
            forIdentifier: .distanceWalkingRunning
        ) else {
            fatalError("*** Unable to get the step count type ***")
        }
        
        healthStore.requestAuthorization(
            toShare: [],
            read: Set([stepCountType, distanceType])
        ) { (success, error) in
            if success {
                print("Authorization OK")
                
                healthKitQuery(
                    dates: ["2020-07-06", "2021-01-07"],
                    healthStore: healthStore,
                    quantityType: stepCountType,
                    unit: HKUnit.count()
                )
                healthKitQuery(
                    dates: ["2020-07-06", "2021-01-07"],
                    healthStore: healthStore,
                    quantityType: distanceType,
                    unit: HKUnit.meter()
                )
            } else {
                print("Authorization failed")
            }
        }
    }
}

private func healthKitQuery(
    dates: Array<String>,
    healthStore: HKHealthStore,
    quantityType: HKQuantityType,
    unit: HKUnit
) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.locale = Locale.current
    
    let dateKeyFormatter = DateFormatter()
    dateKeyFormatter.dateFormat = "yyyy-MM-dd"
    dateKeyFormatter.timeZone = TimeZone.current
    dateKeyFormatter.locale = Locale.current
    
    let startDate = dateFormatter.date(
        from: "\(dates[0])T00:00:00"
    )!
    let anchorDate = dateFormatter.date(
        from: "\(dates[1])T23:59:59"
    )!
    
    var interval = DateComponents()
    interval.day = 1
    
    let datePredicate = HKQuery.predicateForSamples(
        withStart: startDate,
        end: anchorDate
    )
    let sourcesQuery = HKSourceQuery.init(
        sampleType: quantityType,
        samplePredicate: datePredicate
    ) { (query, sources, error) in
        sources?.forEach({ (shit) in
            print("SOURCES = \(shit.bundleIdentifier)")
        })
        
        let filteredSources = sources?.filter({
            $0.bundleIdentifier.lowercased().hasPrefix("com.apple.health")
        })
        
//            if filteredSources == nil {
//                return
//            } else if filteredSources!.isEmpty {
//                print("NO DATA! DONE...")
//                return
//            }
        
        // Only calculate HealthKit data whose not from
        // "com.apple.Health" app. (Manually inputted)
        let sourcesPredicate = HKQuery.predicateForObjects(
            from: filteredSources!
        )
        let wasUserEnteredPredicate = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeyWasUserEntered,
            operatorType: .notEqualTo,
            value: 1
        )
        let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: [
                datePredicate,
//                    sourcesPredicate, // Uncomment this to add sources filtering.
                wasUserEnteredPredicate
            ]
        )
        let query = HKStatisticsCollectionQuery.init(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
            
        query.initialResultsHandler = {
            query,
            results,
            error in

            var data = [String]()

            results?.enumerateStatistics(
                from: startDate,
                to: anchorDate,
                with: { (queryResult, stop) in
                    let value = queryResult.sumQuantity()?.doubleValue(for: unit) ?? 0

                    if value > 0 {
                        data.append("\(dateKeyFormatter.string(from: queryResult.startDate.addingTimeInterval(24 * 60 * 60))),\(value)")
                    }

                    if (queryResult.startDate.compare(anchorDate) == ComparisonResult.orderedSame) {
                        print(data)
                        print("DONE!")
                    }
                }
            )
        }
        
        healthStore.execute(query)
    }
    
    healthStore.execute(sourcesQuery)
}


struct StepsView_Previews: PreviewProvider {
    static var previews: some View {
        StepsView()
    }
}
