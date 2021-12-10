/*
 
Copyright 2021 Microoled
Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 
*/

import UIKit
import ActiveLookSDK

class GlassesTableViewController: UITableViewController {
    
    @IBOutlet weak var scanNavigationItem: UIBarButtonItem!

    
    // MARK: - Private properties

    private let scanDuration: TimeInterval = 10.0
    private let connectionTimeoutDuration: TimeInterval = 5.0
    
    private var scanTimer: Timer?
    private var connectionTimer: Timer?
    
    private var activeLook: ActiveLookSDK = ActiveLookSDK.shared
    private var discoveredGlassesArray: [DiscoveredGlasses] = []
    private var connecting: Bool = false
    
    
    // MARK: - Life cycle
    
    override func viewDidDisappear(_ animated: Bool) {
        activeLook.stopScanning()
        super.viewWillDisappear(animated)
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredGlassesArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GlassesTableViewCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = discoveredGlassesArray[indexPath.row].name
        return cell
    }
    
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if connecting { return }
        connecting = true

        let selectedGlasses = discoveredGlassesArray[indexPath.row]

        selectedGlasses.connect(
            onGlassesConnected: { [weak self] (glasses: Glasses) in
            guard let self = self else { return }

            self.connecting = false
            self.connectionTimer?.invalidate()
                
            if (glasses.isFirmwareAtLeast(version: "4.0")) {
                /*if (glasses.compareFirmwareAtLeast(version: "4.0").rawValue > 0) {
                    let alert = UIAlertController(title: "Update application", message: "The glasses firmware is newer. Check the store for an application update.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true)
                // } else {
                    // if let filePath = Bundle.main.path(forResource: "ConfigDemo-4.0", ofType: "txt") {
                    //     do {
                    //         let cfg = try String(contentsOfFile: filePath)
                    //         glasses.loadConfiguration(cfg: cfg.components(separatedBy: "\n"))
                    //     } catch {}
                    // }
                }*/
                let viewController = CommandsMenuTableViewController(glasses)
                self.navigationController?.pushViewController(viewController, animated: true)
            } else {
                let alert = UIAlertController(title: "Update glasses firmware", message: "The glasses firmware is not up to date.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }, onGlassesDisconnected: { [weak self] in
            guard let self = self else { return }
            
            let alert = UIAlertController(title: "Glasses disconnected", message: "Connection to glasses lost", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.navigationController?.popToRootViewController(animated: true)
            }))

            self.navigationController?.present(alert, animated: true)

        }, onConnectionError: { [weak self] (error: Error) in
            guard let self = self else { return }

            self.connecting = false
            self.connectionTimer?.invalidate()

            let alert = UIAlertController(title: "Error", message: "Connection to glasses failed: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        })

        connectionTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeoutDuration, repeats: false, block: { [weak self] (timer) in
            guard let self = self else { return }

            print("connection to glasses timed out")
            self.connecting = false

            let alert = UIAlertController(title: "Error", message: "The connection to the glasses timed out", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            
            self.tableView.deselectRow(at: indexPath, animated: true)
        })
    }
    
    
    // MARK: - Data
    
    private func addDiscoveredGlasses(_ glasses: DiscoveredGlasses) {
        discoveredGlassesArray.append(glasses)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: self.discoveredGlassesArray.count - 1, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
    

    // MARK: - Scan
    
    private func startScanning() {
        scanNavigationItem.title = "Stop"

        activeLook.startScanning(
            onGlassesDiscovered: { [weak self] (discoveredGlasses: DiscoveredGlasses) in
                self?.addDiscoveredGlasses(discoveredGlasses)

            }, onScanError: { [weak self] (error: Error) in
                self?.stopScanning()
            }
        )

        scanTimer = Timer.scheduledTimer(withTimeInterval: scanDuration, repeats: false) { timer in
            self.stopScanning()
        }
    }
    
    private func stopScanning() {
        activeLook.stopScanning()
        scanNavigationItem.title = "Scan"
        scanTimer?.invalidate()
    }

    
    // MARK: - Actions
    
    @IBAction func onScanButtonTap(_ sender: Any) {
        activeLook.isScanning() ? stopScanning() : startScanning()
    }
}
