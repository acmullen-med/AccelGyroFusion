//
//  ViewController.swift
//  test
//
//  Created by Justin Kwok Lam CHAN on 4/4/21.
//

import Charts
import UIKit
import CoreMotion

class ViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    var ts: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.lineChartView.delegate = self
        
        let set_a: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "x")
        set_a.drawCirclesEnabled = false
        set_a.setColor(UIColor.blue)
        
        let set_b: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "y")
        set_b.drawCirclesEnabled = false
        set_b.setColor(UIColor.red)
        
        let set_c: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "z")
        set_c.drawCirclesEnabled = false
        set_c.setColor(UIColor.green)
        self.lineChartView.data = LineChartData(dataSets: [set_a,set_b,set_c])
    }
    
    @IBAction func startSensors(_ sender: Any) {
        ts=NSDate().timeIntervalSince1970
        label.text=String(format: "%f", ts)
        startAccelerometers()
        startGyros()
        startMagnets()
        startButton.isEnabled = false
        stopButton.isEnabled = true
    }
    
    @IBAction func stopSensors(_ sender: Any) {
        stopAccels()
        stopGyros()
        stopMagnets()
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    // Define necessary values for the magnometer
    
    //let magnet = CMMagnetometerData()
    
    let motion = CMMotionManager()
    var counter:Double = 0
    
    
    var timer_accel:Timer?
    var accel_file_url:URL?
    var accel_fileHandle:FileHandle?
    
    var timer_gyro:Timer?
    var gyro_file_url:URL?
    var gyro_fileHandle:FileHandle?

    var timer_magnet:Timer?
    var magnet_file_url:URL?
    var magnet_fileHandle:FileHandle?
    
    var tiltHistoryVert = 0.0
    var tiltHistoryLateral = 0.0
    var reportVert = 0.0
    var reportLat = 0.0
    
    let xrange:Double = 500
    
    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
       if self.motion.isAccelerometerAvailable {
        // sampling rate can usually go up to at least 100 hz
        // if you set it beyond hardware capabilities, phone will use max rate
          self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
          self.motion.startAccelerometerUpdates()
        
        // create the data file we want to write to
        // initialize file with header line
        do {
            // get timestamp in epoch time
            let file = "accel_file_\(ts).txt"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                accel_file_url = dir.appendingPathComponent(file)
            }

            // write first line of file
            try "ts,x,y,z,tiltUpDown,tiltLeftRight\n".write(to: accel_file_url!, atomically: true, encoding: String.Encoding.utf8)

            accel_fileHandle = try FileHandle(forWritingTo: accel_file_url!)
            accel_fileHandle!.seekToEndOfFile()
        } catch {
            print("Error writing to file \(error)")
        }
        
          // Configure a timer to fetch the data.
          self.timer_accel = Timer(fire: Date(), interval: (1.0/60.0),
                                   repeats: true, block: { [self] (timer) in
             // Get the accelerometer data.
              if let data = self.motion.accelerometerData {
                let x = data.acceleration.x
                let y = data.acceleration.y
                let z = data.acceleration.z
                
                  
                let tiltUpDown = asin(y) * 180 / Double.pi
                let tiltLeftRight = asin(x) * 180 / Double.pi
                let timestamp = NSDate().timeIntervalSince1970
                let text = "\(timestamp), \(x), \(y), \(z), \(tiltUpDown), \(tiltLeftRight)\n"
                //print ("A: \(text)")

                let textTilt = "\(timestamp), \(tiltUpDown)\n"
                print("T: \(textTilt)")
                  
                self.accel_fileHandle!.write(text.data(using: .utf8)!)
                
//                self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(counter), y: tiltUpDown), dataSetIndex: 0)
//                self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(counter), y: tiltLeftRight), dataSetIndex: 1)
                //self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(counter), y: z), dataSetIndex: 2)
//                self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(counter), y: tilt), dataSetIndex: 3)


                // refreshes the data in the graph
//                self.lineChartView.notifyDataSetChanged()
//
//                self.counter = self.counter+1
//
//                // needs to come up after notifyDataSetChanged()
//                if counter < xrange {
//                    self.lineChartView.setVisibleXRange(minXRange: 0, maxXRange: xrange)
//                }
//                else {
//                    self.lineChartView.setVisibleXRange(minXRange: counter, maxXRange: counter+xrange)
//                }
             }
          })

          // Add the timer to the current run loop.
        RunLoop.current.add(self.timer_accel!, forMode: RunLoop.Mode.default)
       }
    }
    
    func startGyros() {
        
       if motion.isGyroAvailable {
          self.motion.gyroUpdateInterval = 1.0 / 60.0
          self.motion.startGyroUpdates()
        
        do {
            let file = "gyro_file_\(ts).txt"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                gyro_file_url = dir.appendingPathComponent(file)
            }

            try "ts,x,y,z\n".write(to: gyro_file_url!, atomically: true, encoding: String.Encoding.utf8)

            gyro_fileHandle = try FileHandle(forWritingTo: gyro_file_url!)
            gyro_fileHandle!.seekToEndOfFile()
        } catch {
            print("Error writing to file \(error)")
        }
        
          // Configure a timer to fetch the accelerometer data.
          self.timer_gyro = Timer(fire: Date(), interval: (1.0/60.0),
                 repeats: true, block: { (timer) in
             // Get the gyro data.
              
             if let data = self.motion.gyroData {
                 
                 
                 if let dataAccel = self.motion.accelerometerData {
                   let xAccel = dataAccel.acceleration.x
                   let yAccel = dataAccel.acceleration.y
                   let zAccel = dataAccel.acceleration.z
                 
                     let tiltUpDown = asin(yAccel) * 180 / Double.pi * -1.0
                     let tiltLeftRight = asin(xAccel) * 180 / Double.pi * -1.0
                     
                  
                     
                 let x = data.rotationRate.x
                let y = data.rotationRate.y
                let z = data.rotationRate.z

                let timestamp = NSDate().timeIntervalSince1970
                let text = "\(timestamp), \(x), \(y), \(z)\n"
                print ("G: \(text)")
                 
                     self.tiltHistoryVert = self.reportVert + (x * self.motion.gyroUpdateInterval * 180 / Double.pi)
                     self.tiltHistoryLateral = self.reportLat + (y * self.motion.gyroUpdateInterval * 180 / Double.pi)
                
                     self.reportVert = tiltUpDown * 0.05 + self.tiltHistoryVert * 0.95
                     self.reportLat = tiltLeftRight * 0.05 + self.tiltHistoryLateral * 0.95

                 
                self.gyro_fileHandle!.write(text.data(using: .utf8)!)
                 
                     self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: self.reportVert), dataSetIndex: 0)
                     self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: self.reportLat), dataSetIndex: 1)
                //self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: ), dataSetIndex: 2)

                // refreshes the data in the graph
                self.lineChartView.notifyDataSetChanged()

                self.counter = self.counter+1

                // needs to come up after notifyDataSetChanged()
                if self.counter < self.xrange {
                    self.lineChartView.setVisibleXRange(minXRange: 0, maxXRange: self.xrange)
                }
                else {
                    self.lineChartView.setVisibleXRange(minXRange: self.counter, maxXRange: self.counter+self.xrange)
                }
             }
             }
          })

          // Add the timer to the current run loop.
          RunLoop.current.add(self.timer_gyro!, forMode: RunLoop.Mode.default)
       }
    }
    
    func startMagnets() {
       if motion.isMagnetometerAvailable {
          self.motion.magnetometerUpdateInterval = 1.0 / 60.0
          self.motion.startMagnetometerUpdates()

        do {
            let file = "magnet_file\(ts).txt"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                magnet_file_url = dir.appendingPathComponent(file)
            }

            try "ts,x,y,z\n".write(to: magnet_file_url!, atomically: true, encoding: String.Encoding.utf8)

            magnet_fileHandle = try FileHandle(forWritingTo: magnet_file_url!)
            magnet_fileHandle!.seekToEndOfFile()
        } catch {
            print("Error writing to file \(error)")
        }

          // Configure a timer to fetch the accelerometer data.
          self.timer_magnet = Timer(fire: Date(), interval: (1.0/60.0),
                 repeats: true, block: { (timer) in
             // Get the gyro data.
              if let data = self.motion.magnetometerData {
              let x = data.magneticField.x
              let y = data.magneticField.y
              let z = data.magneticField.z

                let timestamp = NSDate().timeIntervalSince1970
                let text = "\(timestamp), \(x), \(y), \(z)\n"
//                print ("Magnometer: \(text)")

//                self.magnet_fileHandle!.write(text.data(using: .utf8)!)
//
//                self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: x), dataSetIndex: 0)
//                self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: y), dataSetIndex: 1)
//                self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: z), dataSetIndex: 2)
//
//                // refreshes the data in the graph
//                self.lineChartView.notifyDataSetChanged()
//
//                self.counter = self.counter+1
//
//                // needs to come up after notifyDataSetChanged()
//                if self.counter < self.xrange {
//                    self.lineChartView.setVisibleXRange(minXRange: 0, maxXRange: self.xrange)
//                }
//                else {
//                    self.lineChartView.setVisibleXRange(minXRange: self.counter, maxXRange: self.counter+self.xrange)
//                }
             }
          })

          // Add the timer to the current run loop.
          RunLoop.current.add(self.timer_magnet!, forMode: RunLoop.Mode.default)
       }
    }
    
    func stopAccels() {
       if self.timer_accel != nil {
          self.timer_accel?.invalidate()
          self.timer_accel = nil

          self.motion.stopAccelerometerUpdates()
        
           accel_fileHandle!.closeFile()
       }
    }
    
    func stopGyros() {
       if self.timer_gyro != nil {
          self.timer_gyro?.invalidate()
          self.timer_gyro = nil

          self.motion.stopGyroUpdates()
          
           gyro_fileHandle!.closeFile()
       }
    }
    func stopMagnets() {
       if self.timer_magnet != nil {
          self.timer_magnet?.invalidate()
          self.timer_magnet = nil

          self.motion.stopMagnetometerUpdates()

           magnet_fileHandle!.closeFile()
       }
    }
}

