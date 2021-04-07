//
//  ECGView.swift
//  HealthKitSample
//
//  Created by Rick Krystianne Lim on 4/7/21.
//

import SwiftUI
import HealthKit

struct ECGView: View {
    var body: some View {
        Button("Read ECG", action: readECG)
    }
}

private func readECG() {
    if HKHealthStore.isHealthDataAvailable() {
        print("HKHealthStore available")
        // Add code to use HealthKit here.
        let healthStore = HKHealthStore()
    
        let ecgType = HKObjectType.electrocardiogramType()
        
        healthStore.requestAuthorization(
            toShare: [],
            read: Set([ecgType])
        ) { (success, error) in
            if success {
                print("Authorization OK")
                
                healthKitQuery(
                    dates: ["2020-07-06", "2021-01-07"],
                    healthStore: healthStore
                )
            } else {
                print("Authorization failed")
            }
        }
    }
}

private func healthKitQuery(
    dates: Array<String>,
    healthStore: HKHealthStore
) {
//    let classificationPredicate = HKQuery.predicateForElectrocardiograms(
//        classification: HKElectrocardiogram.Classification.atrialFibrillation
//    )
//    let predicate = NSCompoundPredicate.init(
//        andPredicateWithSubpredicates: [
//            classificationPredicate
//        ]
//    )
    
    let ecgObserverQuery = HKObserverQuery(
        sampleType: HKObjectType.electrocardiogramType(),
        predicate: nil
    ) { (query, completionHandler, error) in
        if let error = error {
            fatalError("*** An error occurred \(error.localizedDescription) ***")
        }
        
        let ecgQuery = HKSampleQuery(
            sampleType: HKObjectType.electrocardiogramType(),
            predicate: nil,//predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { (query, samples, error) in
            if let error = error {
                fatalError("*** An error occurred \(error.localizedDescription) ***")
            }
            
            guard let ecgSamples = samples as? [HKElectrocardiogram] else {
                fatalError("*** Unable to convert \(String(describing: samples)) to [HKElectrocardiogram] ***")
            }
            
            for sample in ecgSamples {
                print("ECG Sample: \(sample)")
                print("Avg Heart Rate: \(sample.averageHeartRate)")
                print("Votage Measurement Count: \(sample.numberOfVoltageMeasurements)")
                print("Sampling Frequency: \(sample.samplingFrequency)")
                
                switch(sample.classification) {
                case .sinusRhythm:
                    print("Classification: sinus rhythm")
                    
                case .atrialFibrillation:
                    print("Classification: atrial fibrillation")
                    
                case .inconclusiveHighHeartRate:
                    print("Classification: inconclusive high heart rate")
                    
                case .inconclusiveLowHeartRate:
                    print("Classification: inconclusive low heart rate")
                    
                case .inconclusivePoorReading:
                    print("Classification: inconclusive poor reading")
                    
                case .inconclusiveOther:
                    print("Classification: inconclusive other")
                    
                case .unrecognized:
                    print("Classification: unrecognized")
                    
                case .notSet:
                    print("Classification: not set")
                    
                @unknown default:
                    print("Classification: unknown")
                }
                
                var ecgSamples = [(Double,Double)] ()
                
                let voltageQuery = HKElectrocardiogramQuery(sample) {
                    (query, result) in
                    
                    switch(result) {
                    case .measurement(let measurement):
    //                    if let voltageQuantity = measurement.quantity(
    //                        for: .appleWatchSimilarToLeadI
    //                    ) {
    //                        // Do something with the voltage quantity here.
    //                    }
                        let sample = (
                            measurement.quantity(
                                for: .appleWatchSimilarToLeadI
                            )!.doubleValue(for: HKUnit.volt()),
                            measurement.timeSinceSampleStart
                        )
                        ecgSamples.append(sample)
                    
                    case .done:
                        print("DONE!!!")
    //                    ecgSamples.forEach { (i, e) in
    //                        print("ECG measurements: \(i)  ,  \(e)")
    //                    }

                    case .error(let error):
                        print("Error: ", error)


                    @unknown default:
                        print("Result unknown...")
                    }
                }


                // Execute the query.
                healthStore.execute(voltageQuery)
            }
        }
        
        healthStore.execute(ecgQuery)
        
        completionHandler()
    }

    healthStore.execute(ecgObserverQuery)
    healthStore.enableBackgroundDelivery(
        for: HKObjectType.electrocardiogramType(),
        frequency: .immediate
    ) { (success, error) in
        if let error = error {
            fatalError("*** An error occurred \(error.localizedDescription) ***")
        }
        
        if (!success) {
            print(">>> NOT SUCCESS")
        }
        
        print(">>>> Enabled background delivery of ECG!")
    }
//    healthStore.enableBackgroundDelivery(sampleType, frequency: .Immediate, withCompletion: {(succeeded: Bool, error: NSError!) in
//
//               if succeeded{
//                   println("Enabled background delivery of weight changes")
//               } else {
//                   if let theError = error{
//                       print("Failed to enable background delivery of weight changes. ")
//                       println("Error = \(theError)")
//                   }
//               }
//           })
}


struct ECGView_Previews: PreviewProvider {
    static var previews: some View {
        ECGView()
    }
}
