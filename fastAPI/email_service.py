# ========================================
# Async Email Service with Queue
# ========================================

import os
import smtplib
import threading
import queue
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import List, Optional
from datetime import datetime
import time

# Email configuration from environment
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
FROM_EMAIL = os.getenv("FROM_EMAIL", SMTP_USER)
FROM_NAME = os.getenv("FROM_NAME", "ManAc System")


class EmailTask:
    """Email task model"""
    
    def __init__(self, to_email: str, subject: str, html_body: str, retry_count: int = 0, max_retries: int = 3):
        self.to_email = to_email
        self.subject = subject
        self.html_body = html_body
        self.retry_count = retry_count
        self.max_retries = max_retries


class EmailQueue:
    """Background email queue processor"""
    
    def __init__(self, num_workers: int = 2):
        self.queue = queue.Queue()
        self.enabled = bool(SMTP_USER and SMTP_PASSWORD)
        self.workers = []
        self.num_workers = num_workers
        self.running = False
    
    def start(self):
        """Start background email workers"""
        if self.running:
            return
        
        self.running = True
        for i in range(self.num_workers):
            worker = threading.Thread(target=self._worker, daemon=True)
            worker.start()
            self.workers.append(worker)
        print(f"[EmailQueue] Started {self.num_workers} workers")
    
    def stop(self):
        """Stop background workers"""
        self.running = False
        # Add sentinel values to unblock workers
        for _ in range(self.num_workers):
            self.queue.put(None)
    
    def _worker(self):
        """Background worker process"""
        while self.running:
            try:
                task = self.queue.get(timeout=1)
                
                if task is None:
                    break
                
                self._send_email(task)
                self.queue.task_done()
                
            except queue.Empty:
                continue
            except Exception as e:
                print(f"[EmailQueue] Worker error: {e}")
    
    def _send_email(self, task: EmailTask):
        """Send a single email"""
        if not self.enabled:
            print(f"[EmailQueue] Email disabled, skipping: {task.subject} to {task.to_email}")
            return
        
        try:
            msg = MIMEMultipart('alternative')
            msg['From'] = f"{FROM_NAME} <{FROM_EMAIL}>"
            msg['To'] = task.to_email
            msg['Subject'] = task.subject
            msg['Date'] = datetime.now().strftime("%a, %d %b %Y %H:%M:%S %z")
            
            part = MIMEText(task.html_body, 'html')
            msg.attach(part)
            
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
                server.starttls()
                server.login(SMTP_USER, SMTP_PASSWORD)
                server.sendmail(FROM_EMAIL, task.to_email, msg.as_string())
            
            print(f"[EmailQueue] Sent: {task.subject} to {task.to_email}")
            
        except Exception as e:
            print(f"[EmailQueue] Error sending to {task.to_email}: {e}")
            
            # Retry logic
            if task.retry_count < task.max_retries:
                task.retry_count += 1
                print(f"[EmailQueue] Retrying ({task.retry_count}/{task.max_retries}): {task.to_email}")
                time.sleep(2 ** task.retry_count)  # Exponential backoff
                self.queue.put(task)
    
    def add_task(self, to_email: str, subject: str, html_body: str):
        """Add email to queue"""
        task = EmailTask(
            to_email=to_email,
            subject=subject,
            html_body=html_body
        )
        self.queue.put(task)
        print(f"[EmailQueue] Queued: {subject} to {to_email}")


# Global email queue instance
email_queue = EmailQueue(num_workers=2)


class EmailService:
    """Async email service using queue"""
    
    def __init__(self):
        # Start the queue processor
        email_queue.start()
    
    def send_welcome_email(self, email: str, name: str):
        """Queue welcome email"""
        subject = "Bienvenue sur ManAc - Gestion de Stock"
        html_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto;">
                <h1 style="color: #00A884;">Bienvenue {name}!</h1>
                <p>Votre compte ManAc a été créé avec succès.</p>
                <p>Vous pouvez maintenant:</p>
                <ul>
                    <li>Gérer votre inventaire de stock</li>
                    <li>Enregistrer les emprunts d'équipements</li>
                    <li>Suivre les mouvements de stock</li>
                </ul>
                <p style="margin-top: 30px; color: #666;">
                    Cordialement,<br>
                    L'équipe ManAc
                </p>
            </div>
        </body>
        </html>
        """
        email_queue.add_task(email, subject, html_body)
    
    def send_borrow_confirmation(
        self, 
        email: str, 
        borrower_name: str, 
        items: List[dict],
        checkout_id: str,
        return_date: Optional[datetime] = None
    ):
        """Queue borrow confirmation email"""
        items_html = ""
        for item in items:
            items_html += f"<li><strong>{item['name']}</strong> - Quantité: {item['quantity']}</li>"
        
        return_info = f"<p>Date de retour prévue: {return_date.strftime('%d/%m/%Y')}" if return_date else ""
        
        subject = f"Confirmation d'emprunt - #{checkout_id[:8]}"
        html_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto;">
                <h1 style="color: #00A884;">Confirmation d'emprunt</h1>
                <p>Bonjour <strong>{borrower_name}</strong>,</p>
                <p>Votre emprunt a été enregistré avec succès.</p>
                
                <div style="background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0;">Numéro de prêt: <span style="color: #00A884;">{checkout_id[:8]}</span></h3>
                    <p><strong>ID complet:</strong> {checkout_id}</p>
                </div>
                
                <h3>Équipements empruntés:</h3>
                <ul>{items_html}</ul>
                
                {return_info}
                
                <p>Veuillez conserver ce numéro de prêt pour le retour.</p>
                
                <p style="margin-top: 30px; color: #666;">
                    Cordialement,<br>
                    L'équipe ManAc
                </p>
            </div>
        </body>
        </html>
        """
        email_queue.add_task(email, subject, html_body)
    
    def send_return_confirmation(
        self,
        email: str,
        borrower_name: str,
        items: List[dict],
        checkout_id: str
    ):
        """Queue return confirmation email"""
        items_html = ""
        for item in items:
            items_html += f"<li><strong>{item['name']}</strong></li>"
        
        subject = f"Confirmation de retour - #{checkout_id[:8]}"
        html_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto;">
                <h1 style="color: #00A884;">Confirmation de retour</h1>
                <p>Bonjour <strong>{borrower_name}</strong>,</p>
                <p>Votre retour d'équipements a été enregistré.</p>
                
                <div style="background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0;">Numéro de prêt: <span style="color: #00A884;">{checkout_id[:8]}</span></h3>
                </div>
                
                <h3>Équipements retournés:</h3>
                <ul>{items_html}</ul>
                
                <p style="margin-top: 30px; color: #666;">
                    Merci de votre confiance,<br>
                    L'équipe ManAc
                </p>
            </div>
        </body>
        </html>
        """
        email_queue.add_task(email, subject, html_body)
    
    def send_admin_notification(
        self,
        admin_emails: List[str],
        action: str,
        details: dict
    ):
        """Queue admin notification"""
        details_html = "".join(f"<li><strong>{k}:</strong> {v}</li>" for k, v in details.items())
        
        subject = f"ManAc - Notification: {action}"
        html_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; padding: 20px;">
            <div style="max-width: 600px; margin: 0 auto;">
                <h1 style="color: #FF5722;">Nouvelle activité</h1>
                <p><strong>Action:</strong> {action}</p>
                <ul>{details_html}</ul>
            </div>
        </body>
        </html>
        """
        
        for email in admin_emails:
            email_queue.add_task(email, subject, html_body)


# Singleton instance
email_service = EmailService()
