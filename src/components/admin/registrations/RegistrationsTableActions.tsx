import React from 'react';
import { Button } from '@/components/ui/button';
import { Edit, CheckCircle, Clock } from 'lucide-react';
import { Registration, ApplicationStatus, RegistrationsPermissions } from './types';

interface RegistrationsTableActionsProps {
  registration: Registration;
  permissions: RegistrationsPermissions;
  onStatusUpdate: (id: string, status: ApplicationStatus) => void;
  onEdit: (registration: Registration) => void;
  onDelete: (id: string) => void;
  onApprovalAction: (registration: Registration) => void;
}

const RegistrationsTableActions: React.FC<RegistrationsTableActionsProps> = ({
  registration,
  permissions,
  onStatusUpdate,
  onEdit,
  onDelete,
  onApprovalAction
}) => {
  console.log('RegistrationsTableActions rendered for:', registration.customer_id, 'permissions:', permissions);

  const handleEdit = () => {
    console.log('Edit button clicked for registration:', registration.id);
    onEdit(registration);
  };

  const handleDelete = () => {
    console.log('Delete button clicked for registration:', registration.id);
    onDelete(registration.id);
  };

  const handleApprovalAction = () => {
    console.log('Approval action clicked for registration:', registration.id);
    onApprovalAction(registration);
  };

  return (
    <div className="flex gap-2">
      {/* Approval button for pending registrations */}
      {permissions.canWrite && registration.status === 'pending' && (
        <Button
          size="sm"
          variant="default"
          onClick={handleApprovalAction}
          className="text-xs"
        >
          <Clock className="h-3 w-3 mr-1" />
          Review
        </Button>
      )}
      
      {/* Approved status indicator */}
      {registration.status === 'approved' && (
        <Button
          size="sm"
          variant="outline"
          disabled
          className="text-xs"
        >
          <CheckCircle className="h-3 w-3 mr-1 text-green-600" />
          Approved
        </Button>
      )}

      {permissions.canWrite && (
        <Button
          size="sm"
          variant="outline"
          onClick={handleEdit}
        >
          <Edit className="h-3 w-3" />
        </Button>
      )}
      {permissions.canDelete && (
        <Button
          size="sm"
          variant="outline"
          onClick={handleDelete}
        >
          Delete
        </Button>
      )}
    </div>
  );
};

export default RegistrationsTableActions;