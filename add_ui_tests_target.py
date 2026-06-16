import re

with open("DreamTracker.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

# Add to PBXBuildFile section
content = content.replace("/* Begin PBXBuildFile section */", """/* Begin PBXBuildFile section */
		00000000000000000000010C /* DreamTrackerUITests.swift in Sources */ = {isa = PBXBuildFile; fileRef = 000000000000000000000212 /* DreamTrackerUITests.swift */; };""")

# Add to PBXContainerItemProxy section
content = content.replace("/* Begin PBXContainerItemProxy section */", """/* Begin PBXContainerItemProxy section */
		000000000000000000000502 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 000000000000000000000001 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 000000000000000000000003;
			remoteInfo = DreamTracker;
		};""")

# Add to PBXFileReference section
content = content.replace("/* Begin PBXFileReference section */", """/* Begin PBXFileReference section */
		000000000000000000000211 /* DreamTrackerUITests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = DreamTrackerUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		000000000000000000000212 /* DreamTrackerUITests.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; name = DreamTrackerUITests.swift; path = DreamTrackerUITests/DreamTrackerUITests.swift; sourceTree = "<group>"; };
		000000000000000000000213 /* DreamTrackerUITests-Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; name = "DreamTrackerUITests-Info.plist"; path = "DreamTrackerUITests/Info.plist"; sourceTree = "<group>"; };""")

# Add to PBXFrameworksBuildPhase section
content = content.replace("/* Begin PBXFrameworksBuildPhase section */", """/* Begin PBXFrameworksBuildPhase section */
		000000000000000000000303 /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};""")

# Add to CustomGroup
custom_group_pos = content.find("000000000000000000000401 /* CustomGroup */ = {")
custom_group_children_pos = content.find("children = (", custom_group_pos)
content = content[:custom_group_children_pos + 12] + "\n\t\t\t\t000000000000000000000408 /* DreamTrackerUITests */," + content[custom_group_children_pos + 12:]

# Add to Products group
products_group_pos = content.find("000000000000000000000404 /* Products */ = {")
products_group_children_pos = content.find("children = (", products_group_pos)
content = content[:products_group_children_pos + 12] + "\n\t\t\t\t000000000000000000000211 /* DreamTrackerUITests.xctest */," + content[products_group_children_pos + 12:]

# Add PBXGroup definition
content = content.replace("/* Begin PBXGroup section */", """/* Begin PBXGroup section */
		000000000000000000000408 /* DreamTrackerUITests */ = {
			isa = PBXGroup;
			children = (
				000000000000000000000212 /* DreamTrackerUITests.swift */,
				000000000000000000000213 /* DreamTrackerUITests-Info.plist */,
			);
			name = DreamTrackerUITests;
			sourceTree = "<group>";
		};""")

# Add PBXNativeTarget definition
content = content.replace("/* Begin PBXNativeTarget section */", """/* Begin PBXNativeTarget section */
		00000000000000000000000D /* DreamTrackerUITests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 000000000000000000000804 /* Build configuration list for PBXNativeTarget "DreamTrackerUITests" */;
			buildPhases = (
				000000000000000000000705 /* Sources */,
				000000000000000000000303 /* Frameworks */,
				000000000000000000000706 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				000000000000000000000602 /* PBXTargetDependency */,
			);
			name = DreamTrackerUITests;
			productName = DreamTrackerUITests;
			productReference = 000000000000000000000211 /* DreamTrackerUITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		};""")

# Add targets in PBXProject
project_pos = content.find("000000000000000000000001 /* Project object */ = {")
project_targets_pos = content.find("targets = (", project_pos)
content = content[:project_targets_pos + 11] + "\n\t\t\t\t00000000000000000000000D /* DreamTrackerUITests */," + content[project_targets_pos + 11:]

# Add TargetAttributes in PBXProject
target_attr_pos = content.find("TargetAttributes = {")
content = content[:target_attr_pos + 20] + """
					00000000000000000000000D = {
						CreatedOnToolsVersion = 14.0;
						TestTargetID = 000000000000000000000003;
					};""" + content[target_attr_pos + 20:]

# Add to PBXResourcesBuildPhase section
content = content.replace("/* Begin PBXResourcesBuildPhase section */", """/* Begin PBXResourcesBuildPhase section */
		000000000000000000000706 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};""")

# Add to PBXSourcesBuildPhase section
content = content.replace("/* Begin PBXSourcesBuildPhase section */", """/* Begin PBXSourcesBuildPhase section */
		000000000000000000000705 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				00000000000000000000010C /* DreamTrackerUITests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};""")

# Add to PBXTargetDependency section
content = content.replace("/* Begin PBXTargetDependency section */", """/* Begin PBXTargetDependency section */
		000000000000000000000602 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 000000000000000000000003 /* DreamTracker */;
			targetProxy = 000000000000000000000502 /* PBXContainerItemProxy */;
		};""")

# Add to XCBuildConfiguration section
content = content.replace("/* Begin XCBuildConfiguration section */", """/* Begin XCBuildConfiguration section */
		000000000000000000000907 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = DreamTrackerUITests/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@loader_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.dreamtracker.app.DreamTrackerUITests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TEST_TARGET_NAME = DreamTracker;
			};
			name = Debug;
		};
		000000000000000000000908 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = DreamTrackerUITests/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@loader_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.dreamtracker.app.DreamTrackerUITests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = NO;
				SWIFT_VERSION = 5.0;
				TEST_TARGET_NAME = DreamTracker;
			};
			name = Release;
		};""")

# Add to XCConfigurationList section
content = content.replace("/* End XCConfigurationList section */", """		000000000000000000000804 /* Build configuration list for PBXNativeTarget "DreamTrackerUITests" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				000000000000000000000907 /* Debug */,
				000000000000000000000908 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */""")

with open("DreamTracker.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)
