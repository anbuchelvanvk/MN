/**
 * ==============================================================================
 * MN JEWEL PARK - GOOGLE DRIVE MEDIA & VIDEO UPLOAD WEBHOOK (APPS SCRIPT)
 * ==============================================================================
 * 
 * Target Google Drive Folder:
 * https://drive.google.com/drive/folders/1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2?usp=drive_link
 * Folder ID: 1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2
 * 
 * Active Deployed Webhook URL:
 * https://script.google.com/macros/s/AKfycbzCv4GGti_wzFZy5vilJjiuh-FxDRNQY0c7ENpkV9JYwzaLjDBh65MDbNhvFJl43jYw/exec
 * 
 * DEPLOYMENT INSTRUCTIONS:
 * 1. Open https://script.google.com
 * 2. Click "New Project" and name it "MN Jewel Park Drive Webhook".
 * 3. Replace all text in Code.gs with the code below.
 * 4. Click "Deploy" (top right) > "New deployment".
 * 5. Click the gear icon next to "Select type" and choose "Web app".
 * 6. Set the fields:
 *    - Description: "MN Jewel Park Direct Media Upload"
 *    - Execute as: "Me" (your Google account)
 *    - Who has access: "Anyone"
 * 7. Click "Deploy", review permissions, and click "Allow".
 * 8. Copy the Web App URL (ends in /exec).
 *    (The default URL in GoogleDriveUploadService is already configured,
 *     or you can update it with your newly deployed URL).
 * ==============================================================================
 */

const SECRET_TOKEN = "MN_JEWEL_PARK_INTERNAL_KEY_2026";
const DEFAULT_MEDIA_FOLDER_ID = "1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2";

/**
 * HTTP POST Handler: Receives Base64 media file from Flutter app and creates it in Google Drive.
 */
function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return responseJson({ status: "error", message: "Empty payload received" });
    }

    const payload = JSON.parse(e.postData.contents);

    // 1. Authenticate with secret key
    if (payload.secretToken !== SECRET_TOKEN) {
      return responseJson({ status: "error", message: "Unauthorized: Invalid secretToken" });
    }

    // 2. Resolve target folder ID (defaults to user's folder)
    const folderId = payload.folderId || DEFAULT_MEDIA_FOLDER_ID;
    const filename = payload.filename || ("Media_Draft_" + new Date().getTime());
    const base64Data = payload.base64;
    const mimeType = payload.mimeType || "application/octet-stream";

    if (!base64Data) {
      return responseJson({ status: "error", message: "Missing file base64 data" });
    }

    // 3. Decode Base64 and create Drive blob
    const decodedBytes = Utilities.base64Decode(base64Data);
    const blob = Utilities.newBlob(decodedBytes, mimeType, filename);

    // 4. Create file inside target Google Drive folder
    const targetFolder = DriveApp.getFolderById(folderId);
    const file = targetFolder.createFile(blob);

    // 5. Grant anyone with link view access so CEO & staff can review
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    const fileId = file.getId();
    const driveUrl = "https://drive.google.com/file/d/" + fileId + "/view";
    const previewUrl = "https://drive.google.com/file/d/" + fileId + "/preview";
    const downloadUrl = "https://drive.usercontent.google.com/download?id=" + fileId + "&export=download";

    return responseJson({
      status: "success",
      fileId: fileId,
      fileName: filename,
      driveUrl: driveUrl,
      previewUrl: previewUrl,
      downloadUrl: downloadUrl,
      folderId: folderId
    });

  } catch (error) {
    return responseJson({
      status: "error",
      message: error.toString()
    });
  }
}

/**
 * HTTP GET Handler: Health check
 */
function doGet(e) {
  return responseJson({
    status: "ok",
    service: "MN Jewel Park Google Drive Media Pipeline",
    mediaFolder: DEFAULT_MEDIA_FOLDER_ID,
    timestamp: new Date().toISOString()
  });
}

function responseJson(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
