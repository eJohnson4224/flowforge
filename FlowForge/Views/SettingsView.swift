//
//  SettingsView.swift
//  flowforge
//
//  Settings panel for configuring workflow folders
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
	@State private var elektroidCliPathDisplay: String? = ElektroidCLI.shared.userConfiguredCliPathForDisplay()

	private func presentAlert(_ alert: NSAlert) {
		if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
			alert.beginSheetModal(for: window)
		} else {
			alert.runModal()
		}
	}

	private func presentLongTextAlert(title: String, text: String) {
		let alert = NSAlert()
		alert.messageText = title

		let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 320))
		scrollView.hasVerticalScroller = true
		scrollView.hasHorizontalScroller = true
		scrollView.borderType = .bezelBorder

		let textView = NSTextView(frame: scrollView.bounds)
		textView.isEditable = false
		textView.isSelectable = true
		textView.isRichText = false
		textView.usesAdaptiveColorMappingForDarkAppearance = true
		textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
		textView.string = text
		scrollView.documentView = textView

		alert.accessoryView = scrollView
		alert.addButton(withTitle: "Copy")
		alert.addButton(withTitle: "Close")

		let copyAction = {
			let pb = NSPasteboard.general
			pb.clearContents()
			pb.setString(text, forType: .string)
		}

		if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
			alert.beginSheetModal(for: window) { response in
				if response == .alertFirstButtonReturn {
					copyAction()
				}
			}
		} else {
			let response = alert.runModal()
			if response == .alertFirstButtonReturn {
				copyAction()
			}
		}
	}

    var body: some View {
        VStack(spacing: 0) {
            // macOS-style header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                #if os(iOS)
                // Close button only on iOS (macOS has window controls)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                #endif
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()
            
            // Folder Configuration
            ScrollView {
                VStack(spacing: 24) {
                    // Sketches Folder
                    FolderConfigRow(
                        state: .sketches,
                        folderURL: appState.sketchesFolderURL,
                        fileCount: appState.sketchesFiles.count,
                        onSelect: {
                            if let url = FolderManager.selectFolder(
                                prompt: "Select your Sketches folder - where raw ideas live"
                            ) {
                                appState.sketchesFolderURL = url
                                appState.saveFolderPaths()
                                appState.retryBootstrap()
                            }
                        },
                        onClear: {
                            appState.sketchesFolderURL = nil
                            appState.sketchesFiles = []
                            appState.saveFolderPaths()
                        }
                    )
                    
                    Divider()
                    
                    // Active Folder
                    FolderConfigRow(
                        state: .active,
                        folderURL: appState.activeFolderURL,
                        fileCount: appState.activeFiles.count,
                        limit: appState.maxActiveSlots,
                        onSelect: {
                            if let url = FolderManager.selectFolder(
                                prompt: "Select your Active folder - where focused work happens (max \(appState.maxActiveSlots) projects)"
                            ) {
                                appState.activeFolderURL = url
                                appState.saveFolderPaths()
                                appState.retryBootstrap()
                            }
                        },
                        onClear: {
                            appState.activeFolderURL = nil
                            appState.activeFiles = []
                            appState.saveFolderPaths()
                        }
                    )
                    
                    Divider()
                    
                    // Archive Folder
                    FolderConfigRow(
                        state: .archive,
                        folderURL: appState.archiveFolderURL,
                        fileCount: appState.archiveFiles.count,
                        onSelect: {
                            if let url = FolderManager.selectFolder(
                                prompt: "Select your Archive folder - where completed work rests"
                            ) {
                                appState.archiveFolderURL = url
                                appState.saveFolderPaths()
                                appState.retryBootstrap()
                            }
                        },
                        onClear: {
                            appState.archiveFolderURL = nil
                            appState.archiveFiles = []
                            appState.saveFolderPaths()
                        }
                    )

                    Divider()
                        .padding(.vertical, 8)

                    // Default State Preference
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Default State on Launch")
                                .font(.headline)
                        }

                        Text("Choose which workflow state to show when you open FlowForge")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Custom state selector with clear buttons
                        HStack(spacing: 12) {
                            ForEach(WorkflowState.allCases, id: \.self) { state in
                                Button(action: {
                                    appState.defaultState = state
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: state.icon)
                                            .font(.title2)
                                        Text(state.rawValue)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        appState.defaultState == state
                                            ? state.color.opacity(0.2)
                                            : Color.secondary.opacity(0.1)
                                    )
                                    .foregroundColor(
                                        appState.defaultState == state
                                            ? state.color
                                            : .secondary
                                    )
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                appState.defaultState == state
                                                    ? state.color
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)

					Divider()
						.padding(.vertical, 8)

					// Digitakt Transfer (Elektroid)
					VStack(alignment: .leading, spacing: 12) {
						HStack {
							Image(systemName: "square.grid.3x3.fill")
								.foregroundColor(.orange)
							Text("Digitakt Transfer")
								.font(.headline)
						}

						Text("FlowForge uses a bundled elektroid-cli for transfers. You can optionally select an external elektroid-cli for testing.")
							.font(.caption)
							.foregroundColor(.secondary)

						#if os(macOS)
						if let path = elektroidCliPathDisplay, !path.isEmpty {
							HStack(alignment: .center, spacing: 8) {
								Text(path)
									.font(.caption)
									.foregroundColor(.secondary)
									.lineLimit(1)
									.truncationMode(.middle)

								Spacer()

								Button("Change") {
									if let url = FolderManager.selectFile(prompt: "Select elektroid-cli executable") {
										do {
											try ElektroidCLI.shared.setUserConfiguredCliURL(url)
											elektroidCliPathDisplay = ElektroidCLI.shared.userConfiguredCliPathForDisplay()
										} catch {
											let nsError = error as NSError
											let alert = NSAlert()
											alert.messageText = "Could not save elektroid-cli selection"
											let probe = ElektroidCLI.shared.sandboxExecutableProbe(for: url)
											alert.informativeText = """
											\(error.localizedDescription)

											domain: \(nsError.domain)
											code: \(nsError.code)
											userInfo: \(nsError.userInfo)

											Possible fixes:
											- Copy elektroid-cli to ~/bin and select that path
											- Rebuild with app-scoped bookmarks entitlement
											- Ensure the file is executable (chmod +x)

											--- Sandbox Probe ---
											\(probe)
											"""
											alert.alertStyle = .warning
											presentAlert(alert)
										}
									}
								}
								.buttonStyle(.bordered)

								Button("Clear") {
									ElektroidCLI.shared.clearUserConfiguredCli()
									elektroidCliPathDisplay = nil
								}
								.buttonStyle(.bordered)
							}

							HStack(spacing: 8) {
								TextField("", text: .constant(path))
									.textFieldStyle(.roundedBorder)
									.font(.caption)
									.disabled(true)
								Button("Copy Path") {
									#if os(macOS)
									let pb = NSPasteboard.general
									pb.clearContents()
									pb.setString(path, forType: .string)
									#endif
								}
								.buttonStyle(.bordered)
							}

							HStack(spacing: 8) {
								Button("Show Diagnostics") {
									DispatchQueue.global(qos: .userInitiated).async {
										let report = ElektroidCLI.shared.cliDiagnosticsSummary()
										DispatchQueue.main.async {
											presentLongTextAlert(title: "Elektroid CLI Diagnostics", text: report)
										}
									}
								}
									.buttonStyle(.bordered)

								Button("Run Sandbox Probe") {
									DispatchQueue.global(qos: .userInitiated).async {
										let path = ElektroidCLI.shared.activeCliPathForDisplay()
											?? ElektroidCLI.shared.userConfiguredCliPathForDisplay()
										guard let path else {
											DispatchQueue.main.async {
												let alert = NSAlert()
												alert.messageText = "Sandbox Probe"
												alert.informativeText = "No elektroid-cli selected."
												alert.alertStyle = .warning
												presentAlert(alert)
											}
											return
										}

										let results = ElektroidSandboxProbe.run(cliURL: URL(fileURLWithPath: path))
										let summary = results.map { step in
											"[\(step.success ? "OK" : "FAIL")] \(step.name)\n\(step.details)"
										}.joined(separator: "\n\n")

										DispatchQueue.main.async {
											let details = "probePath: \(path)\n\n\(summary)"
											presentLongTextAlert(title: "Electroid Sandbox Probe", text: details)
										}
									}
								}
								.buttonStyle(.bordered)

								Spacer()
							}

						} else {
							HStack {
								Button("Select elektroid-cli") {
									if let url = FolderManager.selectFile(prompt: "Select elektroid-cli executable") {
										do {
											try ElektroidCLI.shared.setUserConfiguredCliURL(url)
											elektroidCliPathDisplay = ElektroidCLI.shared.userConfiguredCliPathForDisplay()
										} catch {
											let nsError = error as NSError
											let alert = NSAlert()
											alert.messageText = "Could not save elektroid-cli selection"
											let probe = ElektroidCLI.shared.sandboxExecutableProbe(for: url)
											alert.informativeText = """
											\(error.localizedDescription)

											domain: \(nsError.domain)
											code: \(nsError.code)
											userInfo: \(nsError.userInfo)

											Possible fixes:
											- Copy elektroid-cli to ~/bin and select that path
											- Rebuild with app-scoped bookmarks entitlement
											- Ensure the file is executable (chmod +x)

											--- Sandbox Probe ---
											\(probe)
											"""
											alert.alertStyle = .warning
											presentAlert(alert)
										}
									}
								}
								.buttonStyle(.borderedProminent)
								.tint(.orange)

								Spacer()
							}
						}

						Text("Tip: the common default when building from source is ~/elektroid/src/elektroid-cli.")
							.font(.caption2)
							.foregroundColor(.secondary)
						#else
						Text("Digitakt transfer is currently macOS-only.")
							.font(.caption)
							.foregroundColor(.secondary)
						#endif
					}
					.padding()
					.background(Color.secondary.opacity(0.05))
					.cornerRadius(8)
                }
                .padding()
            }

            Divider()

            // Footer Actions
            HStack {
                Button("Rescan All Folders") {
                    appState.scanAllFolders()
                }
                .disabled(appState.isScanning)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
			.onAppear {
				elektroidCliPathDisplay = ElektroidCLI.shared.userConfiguredCliPathForDisplay()
			}
        .frame(width: 600, height: 580)
    }
}

// MARK: - Folder Configuration Row

struct FolderConfigRow: View {
    let state: WorkflowState
    let folderURL: URL?
    let fileCount: Int
    var limit: Int? = nil
    let onSelect: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: state.icon)
                    .foregroundColor(state.color)
                    .font(.title3)
                
                Text(state.rawValue)
                    .font(.headline)
                    .foregroundColor(state.color)
                
                Spacer()
                
                if let limit = limit {
                    Text("\(fileCount)/\(limit)")
                        .font(.caption)
                        .foregroundColor(fileCount >= limit ? .red : .secondary)
                } else {
                    Text("\(fileCount) files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Folder Path Display
            if let url = folderURL {
                HStack {
                    Text(url.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button("Change") {
                        onSelect()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear") {
                        onClear()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button("Select Folder") {
                    onSelect()
                }
                .buttonStyle(.borderedProminent)
                .tint(state.color)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
