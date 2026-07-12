from pydantic import BaseModel

class SummaryBase(BaseModel):
    active_properties: int
    active_searches: int
    active_results: int
    new_matches: int
