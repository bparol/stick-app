import ProjectDescription

let project = Project(
    name: "Stick",
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
    ]),
    targets: [
        .target(
            name: "Stick",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.parbo.cheatah",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Stick",
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                "UIApplicationSceneManifest": ["UIApplicationSupportsMultipleScenes": false],
            ]),
            sources: ["Stick/Sources/**"],
            resources: [
                "Resources/sky-day.png", "Resources/sky-night.png",
                "Resources/landscape-transparent.png",
                "Resources/stick-*-transparent.png",
                "Resources/sky-illumination.json",
                "Resources/Assets.xcassets",
            ],
            settings: .settings(base: ["ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon"])
        ),
        .target(
            name: "StickTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.bparol.stick.tests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Stick/Tests/**"],
            dependencies: [.target(name: "Stick")]
        ),
        .target(
            name: "StickUITests",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "com.bparol.stick.uitests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["Stick/UITests/**"],
            dependencies: [.target(name: "Stick")]
        ),
        .target(
            name: "StickAutomationRunner",
            destinations: [.iPhone],
            product: .uiTests,
            bundleId: "com.bparol.stick.automation",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "NSLocalNetworkUsageDescription": "Connect to your Mac's Stick automation bridge.",
                "NSAppTransportSecurity": ["NSAllowsLocalNetworking": true],
            ]),
            sources: ["Stick/AutomationRunner/**"],
            dependencies: [.target(name: "Stick")]
        ),
    ],
    schemes: [
        .scheme(
            name: "Stick",
            buildAction: .buildAction(targets: ["Stick"]),
            testAction: .targets(["StickTests", "StickUITests"]),
            runAction: .runAction(executable: "Stick")
        ),
        .scheme(
            name: "StickAutomation",
            buildAction: .buildAction(targets: ["Stick"]),
            testAction: .targets(["StickAutomationRunner"])
        ),
    ]
)
