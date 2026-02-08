import QtQuick
import QtQuick.Layouts 
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.Panels.Settings
import qs.Services.UI
import qs.Widgets

Rectangle {
  id: root

  // Provided by Bar.qml via NWidgetLoader
  property var screen
  property real scaling: 1.0
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  // API configuration
  property string baseUrl: "https://newsapi.org/v2"
  property string country: "us"  // Default country code

  // Last error for diagnostics
  property string lastError: ""
  property string lastResponse: ""
  property string lastUrl: ""

  // Access metadata and per-instance settings
  readonly property string screenName: screen ? screen.name : ""
  
  property var widgetMetadata: BarWidgetRegistry.widgetMetadata[widgetId]
  property var widgetSettings: {
    if (section && sectionWidgetIndex >= 0 && screenName) {
      var widgets = Settings.getBarWidgetsForScreen(screenName)[section];
      if (widgets && sectionWidgetIndex < widgets.length) {
        return widgets[sectionWidgetIndex]
      }
    }
    return {}
  }

  // Widget-specific properties
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property string apiKey: ( widgetSettings.apiKey !== undefined ) ? widgetSettings.apiKey : widgetMetadata.apiKey
  readonly property string category: ( widgetSettings.category !== undefined ) ? widgetSettings.category : widgetMetadata.category 
  readonly property int refreshInterval: ( widgetSettings.refreshInterval !== undefined ) ? widgetSettings.refreshInterval : widgetMetadata.refreshInterval
  readonly property int maxHeadlines: ( widgetSettings.maxHeadlines !== undefined ) ? widgetSettings.maxHeadlines : widgetMetadata.maxHeadlines 
  readonly property int changeNewsInterval: ( widgetSettings.changeNewsInterval !== undefined ) ? widgetSettings.changeNewsInterval : widgetMetadata.changeNewsInterval
  readonly property int rollingSpeed: ( widgetSettings.rollingSpeed !== undefined ) ? widgetSettings.rollingSpeed : widgetMetadata.rollingSpeed
  readonly property int widgetWidth: ( widgetSettings.widgetWidth !== undefined ) ? widgetSettings.widgetWidth : widgetMetadata.widgetWidth

  property var newsData: []
  property int currentIndex: 0
  property bool isLoading: false
  property string errorMessage: ""

  implicitHeight: Math.round(Style.capsuleHeight * scaling)
  implicitWidth: Math.round(widgetWidth * scaling)
  radius: Math.round(Style.radiusS * scaling)
  color: Color.mSurfaceVariant
  border.width: Math.max(1, Style.borderS * scaling)
  border.color: Color.mOutline

  // Auto-refresh timer
  Timer {
    interval: refreshInterval * 60 * 1000
    running: true
    repeat: true
    onTriggered: fetchNews(apiKey, category, maxHeadlines, changeNewsInterval, rollingSpeed)
  }

  // Headline rotation timer
  Timer {
    interval: changeNewsInterval * 1000
    running: newsData.length > 1
    repeat: true
    onTriggered: {
      currentIndex = (currentIndex + 1) % newsData.length
    }
  }

  RowLayout {
    id: layout
    anchors.fill: parent
    anchors.margins: Style.marginXS * scaling
    spacing: Style.marginXS * scaling

    // News icon
    Text {
      text: "📰"
      font.pointSize: Style.fontSizeM * scaling
      Layout.alignment: Qt.AlignVCenter
    }

    // News content with scrolling
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true  // Clip content outside bounds

      property string displayText: {
        if (errorMessage !== "") return errorMessage
        if (isLoading) return "Loading..."
        if (newsData.length === 0) return "No news available"
        return newsData[currentIndex]?.title || "No headline"
      }

      Text {
        id: newsText
        y: (parent.height - height) / 2
        text: parent.displayText
        font.pointSize: Style.fontSizeXS * scaling
        font.weight: Style.fontWeightMedium
        color: errorMessage !== "" ? Color.mError : Color.mOnSurface
        
        // Start from right side if text is too long
        x: textAnimation.running ? 0 : (contentWidth > parent.width ? parent.width - contentWidth : 0)
        
        SequentialAnimation {
          id: textAnimation
          running: newsText.contentWidth > newsText.parent.width && !isLoading && errorMessage === ""
          loops: Animation.Infinite
          
          PauseAnimation { duration: 2000 }  // Wait before scrolling
          NumberAnimation {
            target: newsText
            property: "x"
            from: 0
            to: -(newsText.contentWidth - newsText.parent.width + 20)  // +20 for spacing
            duration: newsText.contentWidth * rollingSpeed  // Speed: 50ms per pixel
            easing.type: Easing.Linear
          }
          PauseAnimation { duration: 1000 }  // Wait at end
          NumberAnimation {
            target: newsText
            property: "x"
            to: 0
            duration: 500  // Quick reset
          }
        }
      }
    }

    // Refresh button
    MouseArea {
      Layout.preferredWidth: Math.round(20 * scaling)
      Layout.preferredHeight: Math.round(20 * scaling)
      cursorShape: Qt.PointingHandCursor
      onClicked: fetchNews(apiKey, category, maxHeadlines, changeNewsInterval, rollingSpeed)

      Text {
        anchors.centerIn: parent
        text: "🔄"
        font.pointSize: Style.fontSizeS * scaling
        opacity: parent.containsMouse ? 1.0 : 0.7
      }
    }
  }

  // Fetch news 
  function fetchNews(apiKey, category, maxHeadlines, changeNewsInterval, rollingSpeed) {
    isLoading = true
    errorMessage = ""
    lastError = ""
    lastResponse = ""

    console.log("[News] API Key:", apiKey)
    console.log("[News] Refresh Interval:", refreshInterval, " Max Headlines: ", maxHeadlines, " Change News Interval: ", changeNewsInterval, " Rolling Speed:", rollingSpeed)
    if (!apiKey || apiKey === "YOUR_API_KEY_HERE") {
      lastError = "API_KEY_NOT_CONFIGURED: Please configure your API key"
      console.log("[News] Error: API key not configured")
      return {}
    }

    var xhr = new XMLHttpRequest()
    var url = baseUrl + "/top-headlines?country=" + country + 
    "&category=" + category + 
    "&apiKey=" + apiKey

    lastUrl = url.replace(apiKey, "***API_KEY***")
    console.log("[News] Fetching headlines - Category:", category)

    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE) {
        lastResponse = "Status: " + xhr.status + "\n" + xhr.responseText.substring(0, 500)
        console.log("[News] Response received - Status:", xhr.status)

        if (xhr.status === 200) {
          try {
            var response = JSON.parse(xhr.responseText)
            if (response.status === "ok" && response.articles) {
              lastError = "SUCCESS: Fetched " + response.articles.length + " articles"
              console.log("[News] Success: Fetched", response.articles.length, "articles (Total:", response.totalResults + ")")
              newsData = response.articles
              isLoading = false
            } else {
              lastError = "API_ERROR: " + (response.message || "Unknown error")
              console.log("[News] API Error:", response.message || "Unknown error")
            }
          } catch (e) {
            lastError = "PARSE_ERROR: " + e.toString()
            console.log("[News] Parse Error:", e.toString())
          }
        } else if (xhr.status === 401) {
          lastError = "INVALID_API_KEY: HTTP 401"
          console.log("[News] Error: Invalid API key (401)")
        } else if (xhr.status === 429) {
          lastError = "RATE_LIMIT: HTTP 429"
          console.log("[News] Error: Rate limit exceeded (429)")
        } else if (xhr.status === 0) {
          lastError = "NETWORK_ERROR: HTTP 0 (check CORS/network)"
          console.log("[News] Error: Network error or CORS issue (0)")
        } else {
          lastError = "HTTP_ERROR: HTTP " + xhr.status
          console.log("[News] Error: HTTP", xhr.status)
        }
      }
    }

    xhr.open("GET", url)
    xhr.send()
  }
}

