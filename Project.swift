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
            bundleId: "com.bparol.stick",
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
                "Resources/sky-illumination.json",
            ]
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
    ]
)
