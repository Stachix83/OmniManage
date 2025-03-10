from sqlalchemy import Column, Integer, String, Enum
from sqlalchemy.orm import relationship
from app.database import Base
import enum
from werkzeug.security import generate_password_hash, check_password_hash

# Benutzerrolle als Enum definieren
class UserRole(enum.Enum):
    ADMIN = "admin"
    USER = "user"

# User-Modell für die Datenbank
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.USER, nullable=False)

    def verify_password(self, password: str) -> bool:
        return check_password_hash(self.hashed_password, password)

    @staticmethod
    def hash_password(password: str) -> str:
        return generate_password_hash(password)
