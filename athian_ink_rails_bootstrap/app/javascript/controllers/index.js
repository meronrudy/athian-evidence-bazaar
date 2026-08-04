import { application } from "./application"
import CoClaimController from "./co_claim_controller"
import ClipboardController from "./clipboard_controller"
import EvidenceUploadController from "./evidence_upload_controller"
import VerificationToastController from "./verification_toast_controller"

application.register("co-claim", CoClaimController)
application.register("clipboard", ClipboardController)
application.register("evidence-upload", EvidenceUploadController)
application.register("verification-toast", VerificationToastController)
