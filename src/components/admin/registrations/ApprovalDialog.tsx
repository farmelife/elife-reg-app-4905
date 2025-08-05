import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { AlertCircle, CheckCircle, XCircle } from 'lucide-react';
import { Registration } from './types';

interface ApprovalDialogProps {
  registration: Registration | null;
  isOpen: boolean;
  onClose: () => void;
  onApprove: (registrationId: string, feeCollected: number, remarks?: string) => void;
  onReject: (registrationId: string, remarks?: string) => void;
  isLoading: boolean;
}

const ApprovalDialog: React.FC<ApprovalDialogProps> = ({
  registration,
  isOpen,
  onClose,
  onApprove,
  onReject,
  isLoading
}) => {
  const [feeCollected, setFeeCollected] = useState('');
  const [remarks, setRemarks] = useState('');

  // Set default fee when registration changes
  React.useEffect(() => {
    if (registration && isOpen) {
      const defaultFee = registration.categories?.offer_fee || 0;
      setFeeCollected(defaultFee.toString());
    }
  }, [registration, isOpen]);

  const handleApprove = () => {
    if (!registration) return;
    
    const fee = parseFloat(feeCollected) || 0;
    onApprove(registration.id, fee, remarks || undefined);
  };

  const handleReject = () => {
    if (!registration) return;
    onReject(registration.id, remarks || undefined);
  };

  const handleClose = () => {
    setFeeCollected('');
    setRemarks('');
    onClose();
  };

  if (!registration) return null;

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <AlertCircle className="h-5 w-5 text-warning" />
            Approval Decision
          </DialogTitle>
        </DialogHeader>
        
        <div className="space-y-4">
          <div className="p-4 bg-muted rounded-lg">
            <h4 className="font-semibold">{registration.name}</h4>
            <p className="text-sm text-muted-foreground">
              Customer ID: {registration.customer_id}
            </p>
            <p className="text-sm text-muted-foreground">
              Mobile: {registration.mobile_number}
            </p>
            <p className="text-sm text-muted-foreground">
              Category: {registration.categories?.name}
            </p>
          </div>

          <div className="space-y-3">
            <div>
              <Label htmlFor="fee">Fee Collected (₹)</Label>
              <div className="flex gap-2">
                <Input
                  id="fee"
                  type="number"
                  min="0"
                  step="0.01"
                  value={feeCollected}
                  onChange={(e) => setFeeCollected(e.target.value)}
                  placeholder="Enter collected fee amount"
                  className="flex-1"
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    const defaultFee = registration?.categories?.offer_fee || 0;
                    setFeeCollected(defaultFee.toString());
                  }}
                  className="px-3"
                >
                  Reset
                </Button>
              </div>
              {registration?.categories?.offer_fee && (
                <p className="text-xs text-muted-foreground mt-1">
                  Default: ₹{registration.categories.offer_fee}
                </p>
              )}
            </div>

            <div>
              <Label htmlFor="remarks">Remarks (Optional)</Label>
              <Textarea
                id="remarks"
                value={remarks}
                onChange={(e) => setRemarks(e.target.value)}
                placeholder="Add any notes about this approval/rejection..."
                rows={3}
              />
            </div>
          </div>

          <div className="flex gap-3 pt-4">
            <Button
              onClick={handleApprove}
              disabled={isLoading}
              className="flex-1"
              variant="default"
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              Approve
            </Button>
            
            <Button
              onClick={handleReject}
              disabled={isLoading}
              variant="destructive"
              className="flex-1"
            >
              <XCircle className="h-4 w-4 mr-2" />
              Reject
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default ApprovalDialog;