
import React from 'react';
import { Button } from '@/components/ui/button';
import { Edit } from 'lucide-react';
import { Registration, ApplicationStatus, RegistrationsPermissions } from './types';

interface RegistrationsTableActionsProps {
  registration: Registration;
  permissions: RegistrationsPermissions;
  onStatusUpdate: (id: string, status: ApplicationStatus) => void;
  onEdit: (registration: Registration) => void;
  onDelete: (id: string) => void;
}

const RegistrationsTableActions: React.FC<RegistrationsTableActionsProps> = ({
  registration,
  permissions,
  onStatusUpdate,
  onEdit,
  onDelete
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

  return (
    <div className="flex gap-2">
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
